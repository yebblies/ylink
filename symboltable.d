
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
    ImportSymbol[][immutable(ubyte)[]] imports;
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
                if (auto imp = cast(ImportSymbol)sym)
                    imports[imp.modname] ~= imp;
            }
            else if (cast(ImportSymbol)*p && cast(ImportSymbol)sym)
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
            if (auto imp = cast(ImportSymbol)sym)
                imports[imp.modname] ~= imp;
            return sym;
        }
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
        size_t offset;
        enum dirEntrySize = 5 * 4;
        enum importEntrySize = 4;
        // Import Directory
        offset += imports.length * dirEntrySize;
        offset += dirEntrySize; // null entry
        // Import Lookup Tables
        foreach(lib, syms; imports)
            offset += syms.length * importEntrySize;
        offset += importEntrySize; // null entry
        // Hint-Name Table
        foreach(lib, syms; imports)
        {
            offset += (2 + lib.length + 1) & ~1;
            foreach(sym; syms)
                if (sym.expName.length)
                    offset += (2 + sym.expName.length + 1) & ~1;
        }
        foreach(lib, syms; imports)
        {
            foreach(sym; syms)
            {
                auto s = new PublicSymbol(sec, cast(immutable(ubyte)[])"__imp_" ~ sym.name, offset);
                sym.sec = sec;
                sym.offset = offset;
                offset += importEntrySize;
                this.add(s);
            }
        }
        offset += importEntrySize; // null entry
        sec.length = offset;
        //writeln("Defined import segment: ", offset, " bytes");
        sectab.add(sec);
    }
    void defineSpecial(SectionTable sectab)
    {
        auto dataend = new Section(cast(immutable(ubyte)[])"__dataend", SectionClass.Data, SectionAlign.align_1, 0);
        auto bssend = new Section(cast(immutable(ubyte)[])"__bssend", SectionClass.BSS, SectionAlign.align_1, 0);
        sectab.add(dataend);
        sectab.add(bssend);
        add(new PublicSymbol(dataend, cast(immutable(ubyte)[])"__edata", 0));
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
            }
        }
        foreach(sym; hiddenSyms)
        {
            if (auto s = cast(ComdefSymbol)sym)
            {
                auto sec = new Section(cast(immutable(ubyte)[])"_DATA$" ~ s.name, SectionClass.Data, SectionAlign.align_1, s.size);
                s.sec = sec;
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
