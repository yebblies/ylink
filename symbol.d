
import std.stdio;

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
    ObjectFile mod;
    Segment seg;
    immutable(ubyte)[] name;
    uint offset;
    uint references;
    Comdat comdat;

    this(ObjectFile mod, Segment seg, immutable(ubyte)[] name, uint offset, Comdat comdat = Comdat.Unique)
    {
        this.mod = mod;
        this.seg = seg;
        this.name = name;
        this.offset = offset;
        this.references = 0;
        this.comdat = comdat;
    }
    void dump()
    {
        if (mod)
            writeln("Symbol: ", cast(string)name, " = ", cast(string)mod.name, ":", cast(string)seg.name, "+", offset, " (", references, ")");
        else
            writeln("Extern: ", cast(string)name, " (", references, ")");
    }
}
