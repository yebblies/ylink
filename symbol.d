
import std.conv;
import std.stdio;

import modules;
import objectfile;
import section;

enum Comdat
{
    Unique,
    Any,
    Max,
}

abstract class Symbol
{
    immutable(ubyte)[] name;
    bool isLocal;
    uint refCount;
    this(immutable(ubyte)[] name, uint refCount, bool isLocal = false)
    {
        this.name = name;
        this.refCount = refCount;
        this.isLocal = isLocal;
    }
    abstract void dump();
}

final class PublicSymbol : Symbol
{
    Section sec;
    uint offset;
    this(Section sec, immutable(ubyte)[] name, uint offset)
    {
        super(name, 0);
        this.sec = sec;
        this.offset = offset;
    }
    override void dump()
    {
        writeln("Public: ", cleanString(name), " = ", sec ? cast(string)sec.fullname : "_abs_", " (", cast(void*)sec, ")", "+", offset, " (", refCount, ")");
    }
}

final class ExternSymbol : Symbol
{
    Symbol sym;
    this(immutable(ubyte)[] name)
    {
        super(name, 1);
    }
    override void dump()
    {
        writeln("Extern: ", cleanString(name), " (", refCount, ")");
    }
}

final class ComdatSymbol : Symbol
{
    Section sec;
    CombinedSection csec;
    uint offset;
    Comdat comdat;
    this(Section sec, CombinedSection csec, immutable(ubyte)[] name, uint offset, Comdat comdat, bool isLocal)
    {
        super(name, 0, isLocal);
        this.sec = sec;
        this.csec = csec;
        this.offset = offset;
        this.comdat = comdat;
    }
    override void dump()
    {
        writeln("Comdat: ", cleanString(name), " = ", sec ? cast(string)sec.fullname : "_abs_", "+", offset, " (", comdat, ")", isLocal ? " Local" : "", " (", refCount, ")");
    }
}

final class ComdefSymbol : Symbol
{
    uint size;
    this(immutable(ubyte)[] name, uint size)
    {
        super(name, 0);
        this.size = size;
    }
    override void dump()
    {
        writeln("Comdef: ", cleanString(name), " (", size, ")", " (", refCount, ")");
    }
}

final class ImportSymbol : Symbol
{
    immutable(ubyte)[] modname;
    ushort expOrd;
    immutable(ubyte)[] expName;
    this(immutable(ubyte)[] modname, ushort expOrd, immutable(ubyte)[] intName, immutable(ubyte)[] expName)
    {
        super(intName, 0);
        this.modname = modname;
        this.expOrd = expOrd;
        this.expName = expName;
    }
    override void dump()
    {
        writeln("Import: ", cleanString(name), " = ", cast(string)modname, ":", expName.length ? cast(string)expName : to!string(expOrd), " (", refCount, ")");
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
