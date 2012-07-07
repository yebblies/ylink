
import std.algorithm;
import std.conv;
import std.exception;
import std.stdio;

import modules;
import symbol;

class SymbolTable
{
    Symbol[immutable(ubyte)[]] symbols;
    Symbol[] undefined;
    Symbol entryPoint;
    Symbol[] imports;

    Symbol searchName(immutable(ubyte)[] name)
    {
        auto p = name in symbols;
        return p ? *p : null;
    }
    void setEntry(Symbol sym)
    {
        enforce(!entryPoint, "Multiple entry points defined");
        entryPoint = sym;
    }
    void add(Symbol sym)
    {
        if (auto p = sym.name in symbols)
        {
            if (cast(ExternSymbol)sym)
            {
                // Redefining an extern symbol is a no-op
            }
            else if (cast(ExternSymbol)*p)
            {
                removeUndefined(*p);
                *p = sym;
                if (cast(ImportSymbol)sym)
                    imports ~= sym;
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
                if (s.comdat == Comdat.Any)
                {
                }
                else
                {
                    enforce(false, "Comdat type " ~ to!string(s.comdat) ~ " not implemented");
                }
            }
            else
            {
                p.dump();
                sym.dump();
                enforce(false, "Multiple definitions of symbol " ~ cast(string)sym.name);
            }
        }
        else
        {
            symbols[sym.name] = sym;
            if (cast(ExternSymbol)sym)
                undefined ~= sym;
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
    void purgeLocals()
    {
        immutable(ubyte)[][] names;
        foreach(name, s; symbols)
        {
            if (s.isLocal)
                names ~= name;
        }
        foreach(name; names)
        {
            symbols.remove(name);
        }
    }
    void checkUnresolved()
    {
        size_t undefcount;
        foreach(s; undefined)
        {
            if (!s.name.startsWith(cast(immutable(ubyte)[])"__imp_"))
            {
                writeln("Error: No definition for symbol: ", cast(string)s.name);
                undefcount++;
            }
        }
        enforce(undefcount == 0, to!string(undefcount) ~ " unresolved symbols found");
    }
    void defineImports()
    {
        foreach(s; imports)
        {
            enforce(cast(ImportSymbol)s);
            s.dump();
        }
        writeln(imports.length, " imports");
    }
    void defineSpecial()
    {
        add(new PublicSymbol(null, cast(immutable(ubyte)[])"__end", 0));
        add(new PublicSymbol(null, cast(immutable(ubyte)[])"__edata", 0));
    }
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
