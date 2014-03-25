
import std.algorithm;
import std.conv;
import std.exception;
import std.stdio;

import modules;
import section;
import sectiontable;
import symbol;

final class SymbolTable
{
    SymbolTable parent;
    Symbol[immutable(ubyte)[]] symbols;
    Symbol[] undefined;
    immutable(ubyte)[] entryPoint;
    Import[][immutable(ubyte)[]] imports;
    Symbol[] hiddenSyms;

    this(SymbolTable parent)
    {
        this.parent = parent;
    }
    Symbol searchName(immutable(ubyte)[] name)
    {
        auto p = name in symbols;
        return p ? *p : null;
    }
    Symbol deepSearch(immutable(ubyte)[] name)
    {
        assert(parent);
        auto p = name in symbols;
        return (p && *p && !cast(ExternSymbol)*p) ? *p : parent.searchName(name);
    }
    void setEntry(immutable(ubyte)[] name)
    {
        if (parent)
            parent.setEntry(name);
        else
        {
            enforce(!entryPoint.length, "Multiple entry points defined");
            entryPoint = name;
        }
    }
    Symbol add(Symbol sym)
    {
        if (auto p = sym.name in symbols)
        {
            if (cast(ExternSymbol)sym)
            {
                // Redefining an extern symbol is a no-op
                p.refCount++;
            }
            else if (cast(ExternSymbol)*p)
            {
                sym.refCount += p.refCount;
                removeUndefined(*p);
                *p = sym;
            }
            else if (cast(ImportThunkSymbol)*p && cast(ImportThunkSymbol)sym)
            {
                enforce(false, "Redefinition of import " ~ cast(string)sym.name);
            }
            else if (cast(ComdefSymbol)*p && cast(ComdefSymbol)sym)
            {
                auto s = cast(ComdefSymbol)*p;
                s.size = max(s.size, (cast(ComdefSymbol)sym).size);
            }
            else if (cast(PublicSymbol)*p && cast(ComdefSymbol)sym)
            {
            }
            else if (cast(ComdefSymbol)*p && cast(PublicSymbol)sym)
            {
                *p = sym;
            }
            else if (cast(ComdatSymbol)*p && cast(ComdatSymbol)sym)
            {
                auto s = cast(ComdatSymbol)*p;
                auto x = cast(ComdatSymbol)sym;
                enforce(s.comdat == x.comdat, "Comdat type mismatch");
                if (s.comdat == Comdat.Unique)
                {
                    enforce(false, "Multiple definitions of symbol " ~ cast(string)sym.name);
                }
                else if (s.comdat == Comdat.Any)
                {
                }
                else
                {
                    enforce(false, "Comdat type " ~ to!string(s.comdat) ~ " not implemented");
                }
            }
            else
            {
                enforce(false, "Multiple definitions of symbol " ~ cast(string)sym.name);
            }
            return *p;
        }
        else
        {
            symbols[sym.name] = sym;
            if (cast(ExternSymbol)sym)
                undefined ~= sym;
            return sym;
        }
    }
    void add(Import imp)
    {
        if (imp.modname in imports)
        {
            auto imps = imports[imp.modname];
            foreach(i; imps)
            {
                if (i.expName == imp.expName)
                {
                    enforce(false, "Multiple definitions of import " ~ cast(string)imp.expName);
                }
            }
        }
        imports[imp.modname] ~= imp;
    }
    bool hasUndefined()
    {
        return undefined.length != 0;
    }
    void dump()
    {
        writeln("Symbol Table:");
        foreach(s; symbols)
            s.dump();
    }
    void dumpUndefined()
    {
        writeln("Undefined Symbols:");
        foreach(s; undefined)
            s.dump();
    }
    void makeMap(string fn)
    {
        auto f = File(fn, "w");
        foreach(s; symbols)
        {
            f.writefln("%.8X\t%s", s.getAddress(), cast(char[])s.name);
        }
    }
    void merge()
    {
        assert(parent);
        foreach(ref sym; symbols)
        {
            if (!sym.isLocal)
            {
                parent.add(sym);
                sym = null;
            }
            else
                parent.addHidden(sym);
        }
        foreach(lib, imps; imports)
        {
            foreach(i; imps)
            {
                parent.add(i);
            }
        }
    }
    void addHidden(Symbol sym)
    {
        assert(sym.isLocal);
        hiddenSyms ~= sym;
    }
    void checkUnresolved()
    {
        size_t undefcount;
        foreach(s; undefined)
        {
            if (!parent || s.isLocal)
            {
                writeln("Error: No definition for symbol: ", cast(string)s.name);
                undefcount++;
            }
        }
        enforce(undefcount == 0, "Error: " ~ to!string(undefcount) ~ " unresolved symbols found");
        enforce(parent || entryPoint.length, "Error: No entry point defined");
    }
    void defineImports(SectionTable sectab)
    {
        auto sec = new Section(cast(immutable(ubyte)[])".idata", SectionClass.IData, SectionAlign.align_2, 0);
        auto tsec = new Section(cast(immutable(ubyte)[])"TEXT$ImportThunks", SectionClass.Code, SectionAlign.align_4, 0);
        size_t offset;
        size_t toffset;
        enum dirEntrySize = 5 * 4;
        enum importEntrySize = 4;
        // Import Directory
        offset += imports.length * dirEntrySize;
        offset += dirEntrySize; // null entry
        // Import Lookup Tables
        foreach(lib, syms; imports)
        {
            //writefln("lib %s - %d symbols", cast(string)lib, syms.length);
            offset += (syms.length + 1) * importEntrySize;
        }
        // Hint-Name Table
        foreach(lib, imps; imports)
        {
            offset += (1 + lib.length + 1) & ~1;
            foreach(imp; imps)
                if (imp.expName.length)
                    offset += (3 + imp.expName.length + 1) & ~1;
        }
        foreach(lib, imps; imports)
        {
            foreach(imp; imps)
            {
                //writefln("Import: %s at %.8X", cast(string)imp.expName, offset);
                imp.address.sec = sec;
                imp.address.offset = offset;
                offset += importEntrySize;
                assert(imp.thunk);
                imp.thunk.sec = tsec;
                imp.thunk.offset = toffset;
                // sym.sec = tsec;
                // sym.offset = toffset;
                toffset += 6;
            }
            offset += importEntrySize;
        }
        sec.length = offset;
        //writeln("Defined import segment: ", offset, " bytes");
        sectab.add(sec);
        tsec.length = toffset;
        sectab.add(tsec);
    }
    void buildImports(ubyte[] data, uint base)
    {
        void writeWordLE(ref uint offset, ushort d)
        {
            (cast(ushort[])data[offset..offset+2])[0] = d;
            offset += 2;
        }
        void writeDwordLE(ref uint offset, uint d)
        {
            (cast(uint[])data[offset..offset+4])[0] = d;
            offset += 4;
        }
        void writeByte(ref uint offset, ubyte d)
        {
            data[offset] = d;
            offset++;
        }
        void writeString(ref uint offset, in ubyte[] str)
        {
            data[offset..offset+str.length] = str[];
            offset += str.length;
        }
        void writeHint(ref uint offset, immutable(ubyte)[] name)
        {
            offset += 2;
            writeString(offset, name);
            offset++;
            if (offset & 1)
                offset++;
        }
        enum idataRVA = 0x1000;
        auto idataVA = base + idataRVA;
        uint totalImports;
        foreach(lib, imps; imports)
        {
            //writefln("lib %s - %d symbols", cast(string)lib, imps.length);
            totalImports += imps.length + 1;
        }
        uint directoryOffset = 0;
        uint lookupOffset = (imports.length + 1) * 5 * 4;
        uint hintOffset = lookupOffset + (totalImports * 4);
        uint libHintOffset = hintOffset;
        foreach(lib, imps; imports)
            foreach(imp; imps)
                if (imp.expName.length)
                    libHintOffset += (3 + imp.expName.length + 1) & ~1;
        uint addressOffset = libHintOffset;
        foreach(lib, imps; imports)
            addressOffset += (1 + lib.length + 1) & ~1;

        foreach(libname, imps; imports)
        {
            writeDwordLE(directoryOffset, lookupOffset + idataRVA);
            writeDwordLE(directoryOffset, 0);
            writeDwordLE(directoryOffset, 0);
            writeDwordLE(directoryOffset, libHintOffset + idataRVA);
            writeDwordLE(directoryOffset, addressOffset + idataRVA);
            foreach(imp; imps)
            {
                //writefln("Import: %s at %.8X", cast(string)sym.name, addressOffset);
                assert(imp.thunk);
                auto tsec = imp.thunk.sec;
                auto tdata = tsec.data;
                tdata[imp.thunk.offset..imp.thunk.offset+2] = [0xFF, 0x25];
                (cast(uint[])tdata[imp.thunk.offset+2..imp.thunk.offset+6])[0] = addressOffset + idataVA;
                if (imp.expName.length)
                {
                    writeDwordLE(lookupOffset, hintOffset + idataRVA);
                    writeDwordLE(addressOffset, hintOffset + idataRVA);
                    writeHint(hintOffset, imp.expName);
                }
                else
                {
                    writeDwordLE(lookupOffset, 0x80000000 | imp.expOrd);
                    writeDwordLE(addressOffset, 0x80000000 | imp.expOrd);
                }
            }
            lookupOffset += 4;
            addressOffset += 4;
            writeString(libHintOffset, libname);
            libHintOffset++;
        }
    }
    void defineSpecial(SectionTable sectab, uint base)
    {
        auto textend = new Section(cast(immutable(ubyte)[])"__textend", SectionClass.Code, SectionAlign.align_1, 0);
        auto dataend = new Section(cast(immutable(ubyte)[])"__dataend", SectionClass.Data, SectionAlign.align_1, 0);
        auto bssend = new Section(cast(immutable(ubyte)[])"__bssend", SectionClass.BSS, SectionAlign.align_1, 0);
        sectab.add(textend);
        sectab.add(dataend);
        sectab.add(bssend);
        add(new AbsoluteSymbol(cast(immutable(ubyte)[])"___ImageBase", 0));
        add(new PublicSymbol(textend, cast(immutable(ubyte)[])"_etext", 0));
        add(new PublicSymbol(textend, cast(immutable(ubyte)[])"__etext", 0));
        add(new PublicSymbol(dataend, cast(immutable(ubyte)[])"_edata", 0));
        add(new PublicSymbol(dataend, cast(immutable(ubyte)[])"__edata", 0));
        add(new PublicSymbol(bssend, cast(immutable(ubyte)[])"_end", 0));
        add(new PublicSymbol(bssend, cast(immutable(ubyte)[])"__end", 0));
    }
    void allocateComdef(SectionTable sectab)
    {
        foreach(sym; symbols)
        {
            if (auto s = cast(ComdefSymbol)sym)
            {
                auto sec = new Section(cast(immutable(ubyte)[])"_DATA$" ~ s.name, SectionClass.Data, SectionAlign.align_1, s.size);
                s.sec = sec;
                sectab.add(sec);
            }
        }
        foreach(sym; hiddenSyms)
        {
            if (auto s = cast(ComdefSymbol)sym)
            {
                auto sec = new Section(cast(immutable(ubyte)[])"_DATA$" ~ s.name, SectionClass.Data, SectionAlign.align_1, s.size);
                s.sec = sec;
                sectab.add(sec);
            }
        }
    }
private:
    void removeUndefined(Symbol s)
    {
        foreach(i, v; undefined)
        {
            if (v is s)
            {
                undefined = undefined[0..i] ~ undefined[i+1..$];
                return;
            }
        }
        assert(0);
    }
}
