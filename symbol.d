
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
    abstract uint getAddress();
    abstract uint getSegment();
    Symbol resolve()
    {
        return this;
    }
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
    override uint getAddress()
    {
        assert(sec);
        return sec.base + offset;
    }
    override uint getSegment()
    {
        assert(sec);
        return sec.container.seg.segid;
    }
}

final class AbsoluteSymbol : Symbol
{
    uint offset;
    this(immutable(ubyte)[] name, uint offset)
    {
        super(name, 0);
        this.offset = offset;
    }
    override void dump()
    {
        writeln("Absolute: ", cleanString(name), " = ", offset);
    }
    override uint getAddress()
    {
        return offset;
    }
    override uint getSegment()
    {
        return 0;
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
    override uint getAddress()
    {
        assert(0);
    }
    override uint getSegment()
    {
        assert(0);
    }
    override Symbol resolve()
    {
        return sym.resolve();
    }
}

final class ComdatSymbol : Symbol
{
    Section sec;
    uint offset;
    Comdat comdat;
    this(Section sec, immutable(ubyte)[] name, uint offset, Comdat comdat, bool isLocal)
    {
        super(name, 0, isLocal);
        this.sec = sec;
        this.offset = offset;
        this.comdat = comdat;
    }
    override void dump()
    {
        writeln("Comdat: ", cleanString(name), " = ", sec ? cast(string)sec.fullname : "_abs_", "+", offset, " (", comdat, ")", isLocal ? " Local" : "", " (", refCount, ")");
    }
    override uint getAddress()
    {
        assert(sec);
        return sec.base + offset;
    }
    override uint getSegment()
    {
        assert(sec);
        return sec.container.seg.segid;
    }
}

final class ComdefSymbol : Symbol
{
    Section sec;
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
    override uint getAddress()
    {
        assert(sec, cleanString(name));
        return sec.base;
    }
    override uint getSegment()
    {
        assert(sec);
        return sec.container.seg.segid;
    }
}

final class Import
{
    immutable(ubyte)[] modname;
    ushort expOrd;
    immutable(ubyte)[] expName;

    ImportThunkSymbol thunk;
    ImportAddressSymbol address;

    this(immutable(ubyte)[] modname, ushort expOrd, immutable(ubyte)[] expName)
    {
        this.modname = modname;
        this.expOrd = expOrd;
        this.expName = expName;
    }
}

final class ImportThunkSymbol : Symbol
{
    Import imp;
    Section sec;
    uint offset;
    this(immutable(ubyte)[] name, Import imp)
    {
        super(name, 0);
        this.imp = imp;
    }
    override void dump()
    {
        writeln("ImportThunk: ", cleanString(name), " = ", cast(string)imp.modname, ":", imp.expName.length ? cast(string)imp.expName : to!string(imp.expOrd), " (", refCount, ")");
    }
    override uint getAddress()
    {
        assert(sec);
        return sec.base + offset;
    }
    override uint getSegment()
    {
        assert(sec);
        return sec.container.seg.segid;
    }
}

final class ImportAddressSymbol : Symbol
{
    Import imp;
    Section sec;
    uint offset;
    this(immutable(ubyte)[] name, Import imp)
    {
        super(name, 0);
        this.imp = imp;
    }
    override void dump()
    {
        writeln("ImportAddress: ", cleanString(name), " = ", cast(string)imp.modname, ":", imp.expName.length ? cast(string)imp.expName : to!string(imp.expOrd), " (", refCount, ")");
    }
    override uint getAddress()
    {
        assert(sec);
        return sec.base + offset;
    }
    override uint getSegment()
    {
        assert(sec);
        return sec.container.seg.segid;
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
