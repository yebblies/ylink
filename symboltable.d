
import std.exception;
import std.stdio;

import symbol;

class SymbolTable
{
    Symbol[immutable(ubyte)[]] symbols;
    uint undefined;

    Symbol searchName(immutable(ubyte)[] name)
    {
        auto p = name in symbols;
        return p ? *p : null;
    }
    void define(Symbol sym)
    {
        if (auto s = searchName(sym.name))
        {
            enforce(!s.mod, "Multiple definitions of symbol " ~ cast(string)sym.name);
            undefined--;
            s.mod = sym.mod;
            s.seg = sym.seg;
            s.offset = sym.offset;
        }
        else
        {
            symbols[sym.name] = sym;
            undefined++;
        }
    }
    void reference(Symbol sym)
    {
        auto s = searchName(sym.name);
        if (s)
            s.references++;
        else
        {
            symbols[sym.name] = sym;
            sym.references++;
        }
    }
    void dump()
    {
        writeln("Symbol Table:");
        foreach(s; symbols)
            s.dump();
    }
}
