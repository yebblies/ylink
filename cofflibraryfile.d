
import std.exception;
import std.stdio;
import std.conv;
import std.string;

import datafile;
import objectfile;
import coffdef;
import coffobjectfile;
import section;
import sectiontable;
import symbol;
import symboltable;
import workqueue;

final class CoffLibraryFile : ObjectFile
{
private:
    DataFile f;
    //size_t[] modules;
    uint[immutable(ubyte)[]] symbols;
public:
    this(DataFile f)
    {
        super(f.filename);
        this.f = f;
    }
    override void dump()
    {
        writeln("COFF Library file: ", f.filename);
        f.seek(0);
    }
    override void loadSymbols(SymbolTable symtab, SectionTable sectab, WorkQueue!string queue, WorkQueue!ObjectFile objects)
    {
        //writeln("COFF Library file: ", f.filename);
        //symtab.dumpUndefined();
        if (!symtab.hasUndefined())
            return;

        f.seek(0);
        enforce(f.readBytes(8) == CoffLibSignature, "Invalid COFF library signature");

        size_t longnamesoffset;
        bool seenFirstLinkerMember;
        while (!f.empty())
        {
            f.alignto(2);
            auto h = f.read!CoffLibHeader();
            if (h.Name == CoffLibLinkerMemberSig)
            {
                if (seenFirstLinkerMember)
                {
                    auto m = f.readDwordLE();
                    auto offs = cast(uint[])f.readBytes(4 * m);
                    auto n = f.readDwordLE();
                    auto inds = cast(ushort[])f.readBytes(2 * n);
                    foreach(i; 0..n)
                    {
                        auto sz = f.readZString();
                        symbols[sz] = offs[inds[i]-1];
                    }
                    break;
                }
                else
                {
                    seenFirstLinkerMember = true;
                    auto n = f.readDwordBE();
                    foreach(i; 0..n)
                    {
                        auto off = f.readDwordBE();
                    }
                    foreach(i; 0..n)
                    {
                        auto sz = f.readZString();
                    }
                }
            }
            else if (h.Name == CoffLibLongnamesMemberSig)
            {
                longnamesoffset = f.tell();
                f.seek(f.tell() + h.Size[].strip.to!uint());
            }
            else if (h.Name[0] == '/')
            {
                assert(0);
            }
            else
            {
                assert(0);
            }
        }

        bool progress;
        do
        {
            progress = false;
            foreach(sym; symtab.undefined)
            {
                // writeln("Searching ", cast(string)sym.name);
                if (sym.name in symbols)
                {
                    f.seek(symbols[sym.name]);

                    auto h = f.read!CoffLibHeader();
                    immutable(ubyte)[] name;
                    if (h.Name[0] == '/')
                    {
                        auto n = h.Name[1..$];
                        while (n[$-1] == ' ')
                            n = n[0..$-1];
                        f.seek(longnamesoffset+to!uint(n));
                        name = f.readZString();
                    }
                    else
                    {
                        name = cast(immutable(ubyte)[])h.Name.idup;
                        size_t i = 1;
                        while (name[i] != '/')
                            i++;
                        name = name[0..i];
                    }

                    auto offset = symbols[sym.name] + CoffLibHeader.sizeof;
                    auto obj = new CoffObjectFile(new DataFile(f, offset));
                    // writeln("Pulling in object ", cast(string)name, " due to undefined symbol: ", cast(string)sym.name);
                    obj.loadSymbols(symtab, sectab, queue, objects);
                    progress = true;
                    break;
                }
            }
        }
        while (progress && symtab.hasUndefined());
    }
    override void loadData(uint tlsBase)
    {
        assert(0, "Libraries can't be loaded like this");
    }
}
