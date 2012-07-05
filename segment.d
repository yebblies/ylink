
import std.stdio;

enum SegmentAlign
{
    align_1 = 1,
    align_2 = 2,
    align_4 = 4,
    align_16 = 16,
    align_page = 4096,
}

enum SegmentClass
{
    Code,
    Data,
    BSS,
    Const,
    TLS,
}

class CombinedSegment
{
    immutable(ubyte)[] name;
    SegmentClass segclass;
    Segment[] members;
    uint length;

    this(immutable(ubyte)[] name, SegmentClass segclass)
    {
        this.name = name;
        this.segclass = segclass;
    }
    void append(Segment seg)
    {
        length = (length + seg.segalign - 1) & ~cast(uint)(seg.segalign - 1);
        seg.offset = length;
        length += seg.length;
        members ~= seg;
    }
    void dump()
    {
        writeln("Segment: ", cast(string)name, " (", segclass, ") ", length, " bytes");
    }
}

class Segment
{
    immutable(ubyte)[] name;
    SegmentClass segclass;
    SegmentAlign segalign;
    uint length;
    uint offset;

    this(immutable(ubyte)[] name, SegmentClass segclass, SegmentAlign segalign, uint length)
    {
        this.name = name;
        this.segclass = segclass;
        this.segalign = segalign;
        this.length = length;
    }
}
