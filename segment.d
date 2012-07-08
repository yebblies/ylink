
import std.exception;
import std.stdio;

import section;

enum SegmentType
{
    Import,
    Export,
    Text,
    TLS,
    Data,
    Const,
    BSS,
    Reloc,
    Debug,
}

final class Segment
{
    SegmentType type;
    uint base;
    uint length;
    CombinedSection[] members;

    this(SegmentType type, uint base)
    {
        this.type = type;
        this.base = base;
    }
    void append(CombinedSection sec)
    {
        members ~= sec;
        sec.seg = this;
        sec.setBase(length);
        length += sec.length;
    }
    void dump()
    {
        writefln("Segment: (%s) 0x%.8X -> 0x%.8X (0x%.8X)", type, base, base + length, length);
    }
}
