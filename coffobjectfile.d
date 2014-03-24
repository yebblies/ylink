
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
        enforce(ch.Machine == IMAGE_FILE_MACHINE_I386);
        enforce(ch.SizeOfOptionalHeader == 0);
        enforce(ch.Characteristics == 0);

        immutable(ubyte[]) getName(in ubyte[] n)
        {
            if (n[0..4] == [0,0,0,0])
            {
                assert(0);
            }
            else
                return n.idup;
        }

        foreach(i; 0..ch.NumberOfSections)
        {
            auto sh = f.read!SectionHeader();
            assert(sh.Name[0] != '/');
            auto name = sh.Name[].idup;
            while (name[$-1] == 0)
                name = name[0..$-1];
            // writefln("%s: 0x%08X", cast(string)sh.Name, sh.Characteristics);
            auto secclass = getSectionClass(sh);
            auto secalign = getSectionAlign(sh);
            auto length = sh.VirtualSize;
            auto sec = new Section(name, secclass, secalign, length);
            sections ~= sec;

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
                        queue.append(defaultExtension(val, "lib"));
                        break;
                    default:
                        assert(0, "Unknown linker directive: " ~ arg);
                    }
                }
            }
        }

        foreach(ref i; 0..ch.NumberOfSymbols)
        {
            f.seek(ch.PointerToSymbolTable + StandardSymbolRecord.sizeof * i);

            auto sym = f.read!StandardSymbolRecord();
            auto name = getName(sym.Name[]);

            // writeln("Symbol at ", i, ": ", cast(string)name);
            // writeln(sym);

            switch(sym.StorageClass)
            {
            case IMAGE_SYM_CLASS_EXTERNAL:
                assert(sym.NumberOfAuxSymbols == 0);
                if (sym.SectionNumber == IMAGE_SYM_UNDEFINED)
                {
                    assert(sym.Value == 0);
                    symtab.add(new ExternSymbol(name));
                }
                else
                {
                    auto sec = sections[sym.SectionNumber-1];
                    symtab.add(new PublicSymbol(sec, name, sym.Value));
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
                        symtab.add(new AbsoluteSymbol(name, sym.Value));
                        continue;
                    }
                    else
                    {
                        assert(0, cast(string)name);
                    }
                }
                break;
            default:
                assert(0, to!string(sym.StorageClass));
            }
            enforce(sym.NumberOfAuxSymbols == 0, cast(string)name);
        }
    }
    override void loadData(uint tlsBase)
    {
        assert(0);
    }
private:
    SectionClass getSectionClass(in ref SectionHeader sh)
    {
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
                 sh.Name == cast(ubyte[])".drectve")
        {
            return SectionClass.Directive;
        }
        else
            assert(0, cast(string)sh.Name);
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
        else
            assert(0);
    }
}

void writeBytes(in ubyte[] data)
{
    write("[");
    foreach(v; data)
        writef("%.2X ", v);
    writeln("]");
}
