
import std.algorithm;
import std.stdio;

import segment;

enum SectionClass
{
    Code,
    Data,
    Const,
    BSS,
    TLS,
    STACK,
    DEBSYM,
    DEBTYP,
    // generated
    IData,
}

enum SectionAlign
{
    align_1 = 1,
    align_2 = 2,
    align_4 = 4,
    align_16 = 16,
    align_page = 4096,
}

final class CombinedSection
{
    immutable(ubyte)[] name;
    immutable(ubyte)[] tag;
    SectionClass secclass;
    Section[] members;
    Segment seg;
    uint base;
    uint length;
    SectionAlign secalign = SectionAlign.align_1;

    this(immutable(ubyte)[] name, immutable(ubyte)[] tag, SectionClass secclass)
    {
        this.name = name;
        this.tag = tag;
        this.secclass = secclass;
    }
    void append(Section sec)
    {
        secalign = max(secalign, sec.secalign);
        length = (length + sec.secalign - 1) & ~cast(uint)(sec.secalign - 1);
        sec.base = length;
        length += sec.length;
        members ~= sec;
        sec.container = this;
    }
    void dump()
    {
        writeln("Section: ", cleanString(name), cleanString(tag), " (", secclass, ") ", length, " bytes align:", secalign);
    }
    void setBase(uint base)
    {
        this.base = base;
        foreach(sec; members)
            sec.base += base;
    }
    void allocate(ubyte[] data)
    {
        foreach(sec; members)
        {
            auto rbase = sec.base-base;
            sec.data = data[rbase..rbase+sec.length];
        }
    }
}

final class Section
{
    immutable(ubyte)[] fullname;
    immutable(ubyte)[] name;
    immutable(ubyte)[] tag;
    SectionClass secclass;
    SectionAlign secalign;
    uint base;
    uint length;
    CombinedSection container;
    ubyte[] data;

    this(immutable(ubyte)[] name, SectionClass secclass, SectionAlign secalign, uint length)
    {
        auto i = name.indexOf('$');
        this.fullname = name;
        this.name = i == -1 ? name : name[0..i];
        this.tag = i == -1 ? null : name[i..$];
        this.secclass = secclass;
        this.secalign = secalign;
        this.length = (length + secalign - 1) & ~(secalign - 1);
        //this.length = length;
    }
}

string cleanString(immutable(ubyte)[] s)
{
    string r;
    foreach(c; s)
    {
        if (c > 0x7F)
            r ~= '*';
        else
            r ~= c;
    }
    return r;
}
