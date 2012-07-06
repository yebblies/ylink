
import std.stdio;

import modules;
import objectfile;
import segment;

enum Comdat
{
    Unique,
    Any,
    Max,
}

class Symbol
{
    Module mod;
    Segment seg;
    immutable(ubyte)[] name;
    immutable(ubyte)[] expname;
    ushort expord;
    uint offset;
    uint references;
    Comdat comdat;
    bool isLocal;

    this(ObjectFile mod, Segment seg, immutable(ubyte)[] name, uint offset, Comdat comdat = Comdat.Unique, bool isLocal = false)
    {
        this.mod = mod;
        this.seg = seg;
        this.name = name;
        this.offset = offset;
        this.references = 0;
        this.comdat = comdat;
        this.isLocal = isLocal;
    }
    this(DllModule mod, ushort expord, immutable(ubyte)[] intname, immutable(ubyte)[] expname)
    {
        this.mod = mod;
        this.name = intname;
        this.expname = expname;
        this.expord = expord;
    }
    void dump()
    {
        if (cast(DllModule)mod)
            writeln("Import: ", cast(string)name, " = ", cast(string)mod.name);
        else if (mod)
            writeln("Symbol: ", cast(string)name, " = ", cast(string)mod.name, ":", seg ? cast(string)seg.name : "null", "+", offset, " (", references, ")");
        else
            writeln("Extern: ", cast(string)name, " (", references, ")");
    }
}
