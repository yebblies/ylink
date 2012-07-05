
import std.exception;
import std.stdio;

import symbol;

class SymbolTable
{
    Symbol[immutable(ubyte)[]] symbols;
    Symbol[] undefined;

    Symbol searchName(immutable(ubyte)[] name)
    {
        auto p = name in symbols;
        return p ? *p : null;
    }
    void define(Symbol sym)
    {
        if (auto s = searchName(sym.name))
        {
            if (s.mod)
            {
                if (sym.comdat == Comdat.Any)
                {
                    return;
                }
                else
                {
                    enforce(false, "Multiple definitions of symbol " ~ cast(string)sym.name);
                }
            }
            else
            {
                foreach(i; 0..undefined.length)
                {
                    if (undefined[i] is s)
                    {
                        undefined = undefined[0..i] ~ undefined[i+1..$];
                        break;
                    }
                }
                s.mod = sym.mod;
                s.seg = sym.seg;
                s.offset = sym.offset;
            }
        }
        else
            symbols[sym.name] = sym;
    }
    void reference(Symbol sym)
    {
        auto s = searchName(sym.name);
        if (s)
            s.references++;
        else
        {
            symbols[sym.name] = sym;
            undefined ~= sym;
            sym.references++;
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
}
