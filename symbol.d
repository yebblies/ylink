
import std.stdio;

import objectfile;
import segment;

class Symbol
{
    ObjectFile mod;
    Segment seg;
    immutable(ubyte)[] name;
    uint offset;
    uint references;

    this(ObjectFile mod, Segment seg, immutable(ubyte)[] name, uint offset)
    {
        this.mod = mod;
        this.seg = seg;
        this.name = name;
        this.offset = offset;
        this.references = 0;
    }
    void dump()
    {
        if (mod)
            writeln("Symbol: ", cast(string)name, " = ", cast(string)mod.name, ":", cast(string)seg.name, "+", offset, " (", references, ")");
        else
            writeln("Extern: ", cast(string)name, " (", references, ")");
    }
}
