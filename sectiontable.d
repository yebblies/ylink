
import std.exception;
import std.stdio;

import section;
import segment;

class SectionTable
{
    CombinedSection[] sections;

    CombinedSection searchName(immutable(ubyte)[] name)
    {
        foreach(s; sections)
            if (s.name == name)
                return s;
        return null;
    }
    CombinedSection add(Section sec)
    {
        auto s = searchName(sec.name);
        if (!s)
        {
            s = new CombinedSection(sec.name, sec.secclass);
            sections ~= s;
        }
        enforce(sec.secclass == s.secclass, "Section " ~ cast(string)sec.name ~ " is in multiple classes");
        s.append(sec);
        return s;
    }
    void dump()
    {
        writeln("Section Table:");
        foreach(s; sections)
            s.dump();
    }
    Segment[] allocateSegments()
    {
        Segment[] segments;
        return null;
    }
}
