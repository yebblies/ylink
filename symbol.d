
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
    this(immutable(ubyte)[] name)
    {
        this.name = name;
    }
    this(immutable(ubyte)[] name, bool isLocal)
    {
        this.name = name;
        this.isLocal = isLocal;
    }
    abstract void dump();
    Symbol resolve()
    {
        return this;
    }
}

class PublicSymbol : Symbol
{
    Section sec;
    uint offset;
    this(Section sec, immutable(ubyte)[] name, uint offset)
    {
        super(name);
        this.sec = sec;
        this.offset = offset;
    }
    override void dump()
    {
        writeln("Public: ", cleanString(name), " = ", sec ? cast(string)sec.name : "_abs_", "+", offset);
    }
}

class ExternSymbol : Symbol
{
    Symbol sym;
    this(immutable(ubyte)[] name)
    {
        super(name);
    }
    override void dump()
    {
        writeln("Extern: ", cleanString(name));
    }
    override Symbol resolve()
    {
        return sym ? sym : this;
    }
}

class ComdatSymbol : Symbol
{
    Section sec;
    CombinedSection csec;
    uint offset;
    Comdat comdat;
    this(Section sec, CombinedSection csec, immutable(ubyte)[] name, uint offset, Comdat comdat, bool isLocal)
    {
        super(name, isLocal);
        this.sec = sec;
        this.csec = csec;
        this.offset = offset;
        this.comdat = comdat;
    }
    override void dump()
    {
        writeln("Comdat: ", cleanString(name), " = ", sec ? cast(string)sec.name : "_abs_", "+", offset, " (", comdat, ")", isLocal ? " Local" : "");
    }
}

class ComdefSymbol : Symbol
{
    uint size;
    this(immutable(ubyte)[] name, uint size)
    {
        super(name);
        this.size = size;
    }
    override void dump()
    {
        writeln("Comdef: ", cleanString(name), " (", size, ")");
    }
}

class ImportSymbol : Symbol
{
    immutable(ubyte)[] modname;
    ushort expOrd;
    immutable(ubyte)[] expName;
    this(immutable(ubyte)[] modname, ushort expOrd, immutable(ubyte)[] intName, immutable(ubyte)[] expName)
    {
        super(intName);
        this.modname = modname;
        this.expOrd = expOrd;
        this.expName = expName;
    }
    override void dump()
    {
        writeln("Import: ", cleanString(name), " = ", cast(string)modname, ":", expName.length ? cast(string)expName : to!string(expOrd));
    }
}

class DirectImportSymbol : Symbol
{
    immutable(ubyte)[] modname;
    ushort expOrd;
    immutable(ubyte)[] expName;
    this(immutable(ubyte)[] modname, ushort expOrd, immutable(ubyte)[] intName, immutable(ubyte)[] expName)
    {
        super(intName);
        this.modname = modname;
        this.expOrd = expOrd;
        this.expName = expName;
    }
    override void dump()
    {
        writeln("XImport: ", cleanString(name), " = ", cast(string)modname, ":", expName.length ? cast(string)expName : to!string(expOrd));
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
