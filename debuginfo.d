
import std.stdio;

class DebugInfo
{
private:
    DebugModule[] modules;
    DebugLibrary[] libraries;
    DebugSourceFile[] sourcefiles;

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
    void dump()
    {
        writeln("Libraries:");
        foreach(i, l; libraries)
            writefln("\t#%d: %s", i+1, cast(string)l.name);
        writeln();
        writeln("Modules:");
        foreach(i, m; modules)
            writefln("\t#%d: %s (%s)", i+1, cast(string)m.name, m.libIndex ? cast(string)libraries[m.libIndex-1].name : "");
        writeln();
        writeln("Source files:");
        foreach(i, s; sourcefiles)
        {
            writefln("\t#%d: %s", i+1, cast(string)s.name);
            foreach(j, b; s.blocks)
            {
                writefln("\t\t[0x%.8X..0x%.8X] (Seg #%d)", b.start, b.end, b.segid);
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

public:
    this(immutable(ubyte)[] name, size_t libIndex)
    {
        this.name = name;
        this.libIndex = libIndex;
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
