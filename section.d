
import std.algorithm;
import std.stdio;

enum SectionAlign
{
    align_1 = 1,
    align_2 = 2,
    align_4 = 4,
    align_16 = 16,
    align_page = 4096,
}

enum SectionClass
{
    Code,
    Data,
    BSS,
    Const,
    TLS,
    ENDBSS,
    STACK,
    DEBSYM,
    DEBTYP,
    IData,
}

class CombinedSection
{
    immutable(ubyte)[] name;
    SectionClass secclass;
    Section[] members;
    uint length;
    SectionAlign secalign = SectionAlign.align_1;

    this(immutable(ubyte)[] name, SectionClass secclass)
    {
        this.name = name;
        this.secclass = secclass;
    }
    void append(Section sec)
    {
        secalign = max(secalign, sec.secalign);
        length = (length + sec.secalign - 1) & ~cast(uint)(sec.secalign - 1);
        sec.offset = length;
        length += sec.length;
        members ~= sec;
        sec.container = this;
    }
    void dump()
    {
        writeln("Section: ", cleanString(name), " (", secclass, ") ", length, " bytes align:", secalign);
    }
}

class Section
{
    immutable(ubyte)[] name;
    SectionClass secclass;
    SectionAlign secalign;
    uint length;
    uint offset;
    CombinedSection container;

    this(immutable(ubyte)[] name, SectionClass secclass, SectionAlign secalign, uint length)
    {
        this.name = name;
        this.secclass = secclass;
        this.secalign = secalign;
        this.length = length;
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
