
import std.algorithm;
import std.exception;
import std.conv;
import std.path;
import std.stdio;
import std.string;

import datafile;
import modules;
import coffdef;
import objectfile;
import section;
import sectiontable;
import segment;
import symbol;
import symboltable;
import workqueue;

public:

final class CoffObjectFile : ObjectFile
{
private:
    DataFile f;
    SymbolTable symtab;
    Section[] sections;
    SectionHeader[] sectionheaders;
    immutable(ubyte)[][] sectionnames;
    Symbol[] symbols;
    bool[] iscomdat;

public:
    this(DataFile f)
    {
        super(f.filename);
        this.f = f;
    }
    override void dump()
    {
        assert(0);
    }
    override void loadSymbols(SymbolTable xsymtab, SectionTable sectab, WorkQueue!string queue, WorkQueue!ObjectFile objects)
    {
        debug(COFFDATA) writeln("COFF Object file: ", f.filename);

        symtab = new SymbolTable(xsymtab);
        objects.append(this);
        f.seek(0);

        auto ch = f.read!CoffHeader();

        if (ch.Machine == IMAGE_FILE_MACHINE_UNKNOWN &&
            ch.NumberOfSections == ushort.max)
        {
            // Import object
            f.seek(f.tell() - CoffHeader.sizeof);
            auto ih = f.read!CoffImportHeader();

            enforce(ih.Version == 0);
            enforce(ih.Machine == IMAGE_FILE_MACHINE_I386);
            enforce((ih.Type & 0b11) == IMPORT_CODE);

            auto name = f.readZString();
            auto modname = f.readZString();

            auto expname = name;
            switch ((ih.Type & 0b11100) >> 2)
            {
            case IMPORT_NAME:
                assert(0);
            case IMPORT_NAME_NOPREFIX:
                assert(0);
            case IMPORT_NAME_UNDECORATE:
                if (expname[0] == '?' ||
                    expname[0] == '@' ||
                    expname[0] == '_')
                    expname = expname[1..$];
                foreach(i; 0..expname.length)
                {
                    if (expname[i] == '@')
                    {
                        expname.length = i;
                        break;
                    }
                }
                break;
            default:
                assert(0);
            }

            auto imp = new Import(modname, 0, expname);
            imp.thunk = new ImportThunkSymbol(name, imp);
            imp.address = new ImportAddressSymbol(cast(immutable(ubyte)[])"__imp_" ~ name, imp);
            symtab.add(imp);
            symtab.add(imp.thunk);
            symtab.add(imp.address);

            // auto s = new ImportThunkSymbol(modname, 0, name, expname);
            // auto s2 = new ImportSymbol(modname, 0, cast(immutable(ubyte)[])"__imp_" ~ name, expname);
            // symtab.add(s);
            // symtab.add(s2);

            symtab.checkUnresolved();
            symtab.merge();
            return;
        }

        enforce(ch.Machine == IMAGE_FILE_MACHINE_I386);
        enforce(ch.SizeOfOptionalHeader == 0);
        enforce(ch.Characteristics == 0);

        auto stringtab = ch.PointerToSymbolTable + StandardSymbolRecord.sizeof * ch.NumberOfSymbols;

        immutable(ubyte)[] readStringTab(uint offset)
        {
            auto pos = f.tell();
            scope(exit) f.seek(pos);
            f.seek(stringtab + offset);
            return f.readZString();
        }

        sectionheaders = cast(SectionHeader[])f.readBytes(SectionHeader.sizeof * ch.NumberOfSections);

        foreach(sh; sectionheaders)
        {
            immutable(ubyte)[] name;
            if (sh.Name[0] == '/')
            {
                auto n = (cast(string)sh.Name[1..$].trim).to!uint();
                name = readStringTab(n);
            }
            else
            {
                name = sh.Name[].idup.trim;
            }
            sectionnames ~= name;

            // writefln("%s: 0x%08X", cast(string)sh.Name, sh.Characteristics);
            auto secclass = getSectionClass(sh);
            auto secalign = getSectionAlign(sh);
            assert(sh.VirtualSize == 0);
            assert(sh.VirtualAddress == 0);
            auto length = sh.SizeOfRawData;
            auto sec = new Section(name, secclass, secalign, length);
            sections ~= sec;
            sectab.add(sec);
            iscomdat ~= (sh.Characteristics & IMAGE_SCN_LNK_COMDAT) != 0;

            if (secclass == SectionClass.Directive)
            {
                auto pos = f.tell();
                scope(exit) f.seek(pos);

                f.seek(sh.PointerToRawData);
                auto data = f.readBytes(sh.SizeOfRawData);

                assert(data[0] != 0xEF, "unicode not supported");
                auto s = cast(string)data;
                while (s.length)
                {
                    string arg;
                    string val;
                    if (!parseMSLinkerSwitch(s, arg, val))
                    {
                        enforce(!s.length || s[0] == '/', "Invalid directives segment: " ~ cast(string)data);
                        break;
                    }

                    switch(arg)
                    {
                    case "/DEFAULTLIB":
                        queue.append(defaultExtension(val, "lib"));
                        break;
                    case "/MERGE":
                        writeln("Warning: /MERGE ignored");
                        break;
                    case "/DISALLOWLIB":
                        writeln("Warning: /DISALLOWLIB ignored");
                        break;
                    default:
                        assert(0, "Unknown linker directive: " ~ arg ~ ":" ~ val);
                    }
                }
            }
        }

        symbols.length = ch.NumberOfSymbols;
        foreach(ref i; 0..ch.NumberOfSymbols)
        {
            f.seek(ch.PointerToSymbolTable + StandardSymbolRecord.sizeof * i);

            auto sym = f.read!StandardSymbolRecord();

            immutable(ubyte)[] name;
            if (sym.Name[0..4] == [0,0,0,0])
            {
                name = readStringTab((cast(uint[])sym.Name[4..8])[0]);
            }
            else
                name = sym.Name.idup.trim;

            // writeln("Symbol at ", i, ": ", cast(string)name);
            // writeln(sym);

            switch(sym.StorageClass)
            {
            case IMAGE_SYM_CLASS_EXTERNAL:
                assert(sym.NumberOfAuxSymbols == 0);
                if (sym.SectionNumber == IMAGE_SYM_UNDEFINED)
                {
                    if (sym.Value == 0)
                    {
                        symbols[i] = symtab.add(new ExternSymbol(name));
                    }
                    else
                    {
                        symbols[i] = symtab.add(new ComdefSymbol(name,  sym.Value));
                    }
                }
                else if (sym.SectionNumber == IMAGE_SYM_ABSOLUTE)
                {
                    assert(sym.Type == 0);
                    symbols[i] = symtab.add(new AbsoluteSymbol(name, sym.Value));
                    continue;
                }
                else
                {
                    auto sec = sections[sym.SectionNumber-1];
                    if (iscomdat[sym.SectionNumber-1])
                    {
                        // writeln("Comdat symbol ", cast(string)name);
                        symbols[i] = symtab.add(new ComdatSymbol(sec, name, sym.Value, Comdat.Any, false));
                    }
                    else
                    {
                        // writeln("Public symbol ", cast(string)name);
                        symbols[i] = symtab.add(new PublicSymbol(sec, name, sym.Value));
                    }
                }
                break;
            case IMAGE_SYM_CLASS_STATIC:
                if (sym.SectionNumber == IMAGE_SYM_ABSOLUTE)
                {
                    // absolute symbol
                    assert(sym.Type == 0);
                    assert(sym.NumberOfAuxSymbols == 0);
                    auto s = new AbsoluteSymbol(name, sym.Value);
                    s.isLocal = true;
                    symbols[i] = symtab.add(s);
                    continue;
                }
                else
                {
                    if (sym.Value == 0)
                    {
                        auto ss = symtab.searchName(name);
                        if (ss)
                        {
                            symbols[i] = ss;
                            break;
                        }
                    }
                    // writeln("Static symbol ", cast(string)name);
                    auto sec = sections[sym.SectionNumber-1];
                    auto s = new PublicSymbol(sec, name, sym.Value);
                    s.isLocal = true;
                    symbols[i] = symtab.add(s);
                }
                break;
            case IMAGE_SYM_CLASS_LABEL:
                auto sec = sections[sym.SectionNumber-1];
                auto s = new AbsoluteSymbol(cast(immutable(ubyte)[])to!string(cast(void*)sec) ~ '$' ~ name, 0);
                symbols[i] = symtab.add(s);
                continue;
            default:
                assert(0, to!string(sym.StorageClass));
            }
            i += sym.NumberOfAuxSymbols;
        }
        symtab.checkUnresolved();
        symtab.merge();
    }
    override void loadData(uint tlsBase)
    {
        f.seek(0);

        auto ch = f.read!CoffHeader();

        if (ch.Machine == IMAGE_FILE_MACHINE_UNKNOWN &&
            ch.NumberOfSections == ushort.max)
        {
            // Import object
            return;
        }

        enforce(ch.Machine == IMAGE_FILE_MACHINE_I386);
        enforce(ch.SizeOfOptionalHeader == 0);
        enforce(ch.Characteristics == 0);

        auto stringtab = ch.PointerToSymbolTable + StandardSymbolRecord.sizeof * ch.NumberOfSymbols;

        foreach(i, sh; sectionheaders)
        {
            auto name = sectionnames[i];
            auto sec = sections[i];

            //writeln(cast(string)this.name, " ", cast(string)name);
            if (sh.SizeOfRawData && sec.data.length)
            {
                if (sec.data.length != sh.SizeOfRawData)
                {
                    writeln("Warning: comdat length mismatch");
                    continue;
                }
                f.seek(sh.PointerToRawData);
                auto data = f.readBytes(sh.SizeOfRawData);
                sec.data[] = data[];

                f.seek(sh.PointerToRelocations);
                foreach(j; 0..sh.NumberOfRelocations)
                {
                    auto r = f.read!CoffRelocation();
                    auto sym = symbols[r.SymbolTableIndex];
                    assert(sym);
                    sym = sym.resolve();
                    assert(!cast(ExternSymbol)sym);
                    //writeln(sym);

                    assert(ch.Machine == IMAGE_FILE_MACHINE_I386);
                    switch(r.Type)
                    {
                    case IMAGE_REL_I386_DIR32:
                        auto targetAddress = sym.getAddress();
                        auto baseAddress = 0;
                        auto offset = r.VirtualAddress;
                        (cast(uint[])sec.data[offset..offset+4])[0] += targetAddress - baseAddress;
                        break;
                    case IMAGE_REL_I386_DIR32NB:
                        auto targetAddress = sym.getAddress();
                        auto baseAddress = sec.base + r.VirtualAddress;
                        auto offset = r.VirtualAddress;
                        (cast(uint[])sec.data[offset..offset+4])[0] += targetAddress - baseAddress;
                        break;
                    case IMAGE_REL_I386_SECTION:
                        auto targetAddress = sec.container.base;
                        auto baseAddress = 0;
                        auto offset = r.VirtualAddress;
                        (cast(uint[])sec.data[offset..offset+4])[0] += targetAddress - baseAddress;
                        break;
                    case IMAGE_REL_I386_SECREL:
                        auto targetAddress = sym.getAddress();
                        auto baseAddress = sec.container.base;
                        auto offset = r.VirtualAddress;
                        (cast(uint[])sec.data[offset..offset+4])[0] += targetAddress - baseAddress;
                        break;
                    case IMAGE_REL_I386_REL32:
                        auto targetAddress = sym.getAddress();
                        auto baseAddress = sec.base + r.VirtualAddress;
                        auto offset = r.VirtualAddress;
                        (cast(uint[])sec.data[offset..offset+4])[0] += targetAddress - baseAddress;
                        break;
                    default:
                        assert(0, "Unhandled relocation: 0x" ~ r.Type.to!string(16));
                    }
                }
            }
        }
    }
private:
    SectionClass getSectionClass(in ref SectionHeader sh)
    {
        auto name = sh.Name.trim;
        if (sh.Characteristics & IMAGE_SCN_CNT_CODE)
        {
            return SectionClass.Code;
        }
        else if (sh.Characteristics & IMAGE_SCN_CNT_INITIALIZED_DATA)
        {
            return SectionClass.Data;
        }
        else if (sh.Characteristics & IMAGE_SCN_CNT_UNINITIALIZED_DATA)
        {
            return SectionClass.BSS;
        }
        else if (sh.Characteristics & IMAGE_SCN_LNK_INFO &&
                 name == cast(ubyte[])".drectve")
        {
            return SectionClass.Directive;
        }
        else if (sh.Characteristics & IMAGE_SCN_LNK_INFO &&
                 name == cast(ubyte[])".sxdata")
        {
            return SectionClass.Discard;
        }
        else
            assert(0, cast(string)name);
    }
    SectionAlign getSectionAlign(in ref SectionHeader sh)
    {
        if (sh.Characteristics & IMAGE_SCN_ALIGN_1BYTES)
        {
            return SectionAlign.align_1;
        }
        else if (sh.Characteristics & IMAGE_SCN_ALIGN_2BYTES)
        {
            return SectionAlign.align_2;
        }
        else if (sh.Characteristics & IMAGE_SCN_ALIGN_4BYTES)
        {
            return SectionAlign.align_4;
        }
        else if (sh.Characteristics & IMAGE_SCN_ALIGN_16BYTES)
        {
            return SectionAlign.align_16;
        }
        else if (sh.Characteristics & IMAGE_SCN_LNK_INFO)
        {
            // These don't get linked, so we don't care about alignment
            return SectionAlign.align_1;
        }
        else
            assert(0, to!string(sh.Characteristics, 16));
    }
}

void writeBytes(in ubyte[] data)
{
    write("[");
    foreach(v; data)
        writef("%.2X ", v);
    writeln("]");
}

inout(ubyte)[] trim(inout(ubyte)[] s)
{
    while(s.length && s[$-1] == 0)
        s = s[0..$-1];
    return s;
}

bool parseMSLinkerSwitch(ref string s, out string arg, out string val, bool untilend = false)
{
    arg = null;
    val = null;
    while(s.length && s[0] == ' ')
        s = s[1..$];

    if (!s.length)
        return false;

    if (s[0] != '/')
        return false;

    size_t i = 1;
    while (s.length && s[i] != ':' && s[i] != ' ' && s[i] != '/')
        i++;
    arg = s[0..i].toUpper;

    s = s[i..$];
    if (!s.length || s[0] != ':')
        return true;

    s = s[1..$];
    i = 0;
    if (s[i] == '"')
    {
        i++;
        while (s.length && s[i] != '"')
            i++;
        if (s[i] != '"')
            return false;
        i++;
    }
    else if (untilend)
    {
        val = s[0..$];
        s = null;
        return true;
    }
    else
    {
        while (i < s.length && s[i] != ' ' && s[i] != '/')
            i++;
    }
    val = s[0..i];
    if (val[0] == '"')
    {
        val = val[1..$-1];
        i++;
    }
    s = s[i..$];
    while(s.length && s[0] == ' ')
        s = s[1..$];
    return true;
}
