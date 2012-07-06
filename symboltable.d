
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
                    sym.dump();
                    s.dump();
                    writeln(sym.comdat);
                    writeln(s.comdat);
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
                s.isLocal = sym.isLocal;
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
        foreach(s; undefined)
        {
            writeln("Error: No definition for symbol: ", cast(string)s.name);
        }
        enforce(undefined.length == 0, to!string(undefined.length) ~ " unresolved symbols found");
    }
    void defineImports()
    {
        foreach(s; symbols)
        {
            if (s.mod && cast(DllModule)s.mod)
            {
                writeln("Import: ", cast(string)s.name);
            }
        }
    }
}
