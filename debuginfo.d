
import std.stdio;

class DebugInfo
{
private:
    DebugModule[] modules;
    DebugLibrary[] libraries;
    DebugSourceFile[] sourcefiles;
    DebugSegment[] segments;

public:
    this()
    {
    }

    void addModule(DebugModule m)
    {
        modules ~= m;
    }
    void addLibrary(DebugLibrary l)
    {
        libraries ~= l;
    }
    void addSourceFile(DebugSourceFile s)
    {
        sourcefiles ~= s;
    }
    void addSegment(DebugSegment s)
    {
        segments ~= s;
    }
    void setSegmentName(size_t segid, immutable(ubyte)[] name)
    {
        segments[segid-1].name = name;
    }
    void addModuleSource(size_t moduleid, immutable(ubyte)[] name)
    {
        modules[moduleid-1].addSourceFile(name);
    }
    void dump()
    {
        writeln("Libraries:");
        foreach(i, l; libraries)
            writefln("\t#%d: %s", i+1, cast(string)l.name);
        writeln();
        writeln("Modules:");
        foreach(i, m; modules)
        {
            writefln("\t#%d: %s (%s)", i+1, cast(string)m.name, m.libIndex ? cast(string)libraries[m.libIndex-1].name : "");
            foreach(j, s; m.sourceFiles)
            {
                writefln("\t\t%s", cast(string)s);
            }
        }
        writeln();
        writeln("Segments:");
        foreach(i, s; segments)
        {
            writefln("\t#%d: %s", i+1, cast(string)s.name);
            writefln("\t\t0x%.8X bytes", s.length);
        }
        writeln();
        writeln("Source files:");
        foreach(i, s; sourcefiles)
        {
            writefln("\t#%d: %s", i+1, cast(string)s.name);
            foreach(j, b; s.blocks)
            {
                writefln("\t\t[0x%.8X..0x%.8X] (%s)", b.start, b.end, cast(string)segments[b.segid-1].name);
                foreach(k, l; b.linnums)
                    writefln("\t\t\t0x%.8X: %d", l.offset, l.linnum);
            }
        }
        writeln();
    }
}

class DebugModule
{
private:
    immutable(ubyte)[] name;
    size_t libIndex;
    immutable(ubyte)[][] sourceFiles;

public:
    this(immutable(ubyte)[] name, size_t libIndex)
    {
        this.name = name;
        this.libIndex = libIndex;
    }
    void addSourceFile(immutable(ubyte)[] s)
    {
        sourceFiles ~= s;
    }
}

class DebugLibrary
{
private:
    immutable(ubyte)[] name;

public:
    this(immutable(ubyte)[] name)
    {
        this.name = name;
    }
}

class DebugSourceFile
{
private:
    immutable(ubyte)[] name;
    BlockInfo[] blocks;

public:
    this(immutable(ubyte)[] name)
    {
        this.name = name;
    }
    void addBlock(BlockInfo bi)
    {
        blocks ~= bi;
    }
}

class DebugSegment
{
private:
    immutable(ubyte)[] name;
    uint length;
public:
    this(uint length)
    {
        this.length = length;
    }
}

struct BlockInfo
{
    size_t segid;
    uint start;
    uint end;
    LineInfo[] linnums;
}

struct LineInfo
{
    uint offset;
    uint linnum;
}
