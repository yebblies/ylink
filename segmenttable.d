
import std.exception;
import std.stdio;

import segment;

class SegmentTable
{
    CombinedSegment[] segments;

    CombinedSegment searchName(immutable(ubyte)[] name)
    {
        foreach(s; segments)
            if (s.name == name)
                return s;
        return null;
    }
    CombinedSegment add(Segment seg)
    {
        auto s = searchName(seg.name);
        if (!s)
        {
            s = new CombinedSegment(seg.name, seg.segclass);
            segments ~= s;
        }
        enforce(seg.segclass == s.segclass, "Section " ~ cast(string)seg.name ~ " is in multiple classes");
        s.append(seg);
        return s;
    }
    void dump()
    {
        writeln("Segment Table:");
        foreach(s; segments)
            s.dump();
    }
}
