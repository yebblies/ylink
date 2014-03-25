
import std.algorithm;
import std.exception;
import std.conv;
import std.path;
import std.stdio;

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

        foreach(i; 0..ch.NumberOfSections)
        {
            auto sh = f.read!SectionHeader();
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

            // writefln("%s: 0x%08X", cast(string)sh.Name, sh.Characteristics);
            auto secclass = getSectionClass(sh);
            auto secalign = getSectionAlign(sh);
            auto length = sh.VirtualSize;
            auto sec = new Section(name, secclass, secalign, length);
            sections ~= sec;
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
                    while(s.length && s[0] == ' ')
                        s = s[1..$];
                    if (!s.length)
                        break;
                    assert(s[0] == '/');
                    size_t j = 1;
                    while (s.length && s[j] != ':')
                        j++;
                    auto arg = s[0..j];
                    size_t k = j+1;
                    if (s[k] == '"')
                    {
                        k++;
                        while (s[k] != '"')
                            k++;
                    }
                    while (s[k] != ' ')
                        k++;
                    auto val = s[j+1..k];
                    if (val[0] == '"')
                        val = val[1..$-1];
                    s = s[k+1..$];

                    switch(arg)
                    {
                    case "/DEFAULTLIB":
                    case "/defaultlib":
                        queue.append(defaultExtension(val, "lib"));
                        break;
                    case "/MERGE":
                    case "/merge":
                        writeln("Warning: /MERGE ignored");
                        break;
                    case "/disallowlib":
                        writeln("Warning: /DISALLOWLIB ignored");
                        break;
                    default:
                        assert(0, "Unknown linker directive: " ~ arg ~ ":" ~ val);
                    }
                }
            }
        }

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
                        symtab.add(new ExternSymbol(name));
                    }
                    else
                    {
                        symtab.add(new ComdefSymbol(name,  sym.Value));
                    }
                }
                else if (sym.SectionNumber == IMAGE_SYM_ABSOLUTE)
                {
                    assert(sym.Type == 0);
                    assert(sym.NumberOfAuxSymbols == 0);
                    symtab.add(new AbsoluteSymbol(name, sym.Value));
                    continue;
                }
                else
                {
                    auto sec = sections[sym.SectionNumber-1];
                    if (iscomdat[sym.SectionNumber-1])
                    {
                        // writeln("Comdat symbol ", cast(string)name);
                        symtab.add(new ComdatSymbol(sec, name, sym.Value, Comdat.Any, false));
                    }
                    else
                    {
                        // writeln("Public symbol ", cast(string)name);
                        symtab.add(new PublicSymbol(sec, name, sym.Value));
                    }
                }
                break;
            case IMAGE_SYM_CLASS_STATIC:
                if (sym.Value == 0)
                {
                    // section symbol
                    // do nothing
                    //assert(0, cast(string)name);
                    i += sym.NumberOfAuxSymbols;
                    continue;
                }
                else
                {
                    if (sym.SectionNumber == IMAGE_SYM_ABSOLUTE)
                    {
                        // absolute symbol
                        assert(sym.Type == 0);
                        assert(sym.NumberOfAuxSymbols == 0);
                        auto s = new AbsoluteSymbol(name, sym.Value);
                        s.isLocal = true;
                        symtab.add(s);
                        continue;
                    }
                    else
                    {
                        // writeln("Static symbol ", cast(string)name);
                        auto sec = sections[sym.SectionNumber-1];
                        auto s = new PublicSymbol(sec, name, sym.Value);
                        s.isLocal = true;
                        symtab.add(s);
                    }
                }
                break;
            case IMAGE_SYM_CLASS_LABEL:
                continue;
            default:
                assert(0, to!string(sym.StorageClass));
            }
            enforce(sym.NumberOfAuxSymbols == 0, cast(string)name);
        }
        symtab.checkUnresolved();
        symtab.merge();
    }
    override void loadData(uint tlsBase)
    {
        assert(0);
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
