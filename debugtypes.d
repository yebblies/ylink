
import std.conv;

enum
{
    M_CONST = 0x1,
    M_VOLATILE = 0x2,
    M_UNALIGNED = 0x4,
}

abstract class DebugType
{
    uint modifiers;

    abstract DebugType copy();
    abstract DebugType resolve(DebugType[] types);
    DebugType addMod(uint mod)
    {
        if ((modifiers & mod) != modifiers)
        {
            auto t = copy();
            t.modifiers |= mod;
            return t;
        }
        return this;
    }
}

enum
{
    BT_VOID,
    BT_CHAR,
    BT_WCHAR,
    BT_DCHAR,
    BT_BOOL,
    BT_BYTE,
    BT_UBYTE,
    BT_SHORT,
    BT_USHORT,
    BT_INT,
    BT_UINT,
    BT_LONG,
    BT_ULONG,
    BT_FLOAT,
    BT_DOUBLE,
    BT_REAL,
    BT_CFLOAT,
    BT_CDOUBLE,
    BT_CREAL,
}

class DebugTypeBasic : DebugType
{
    uint bt;
    this(uint bt)
    {
        this.bt = bt;
    }
    override DebugTypeBasic copy()
    {
        return new DebugTypeBasic(bt);
    }
    DebugType resolve(DebugType[] types)
    {
        return this;
    }
}

class DebugTypePointer : DebugType
{
    DebugType ntype;
    this(DebugType ntype)
    {
        this.ntype = ntype;
    }
    override DebugTypePointer copy()
    {
        return new DebugTypePointer(ntype);
    }
    DebugType resolve(DebugType[] types)
    {
        ntype = ntype.resolve(types);
        return this;
    }
}

class DebugTypeReference : DebugType
{
    DebugType ntype;
    this(DebugType ntype)
    {
        this.ntype = ntype;
    }
    override DebugTypeReference copy()
    {
        return new DebugTypeReference(ntype);
    }
    DebugType resolve(DebugType[] types)
    {
        ntype = ntype.resolve(types);
        return this;
    }
}

class DebugTypeFunction : DebugType
{
    DebugType rtype;
    DebugType atype;
    DebugType classtype;
    DebugType thistype;
    this(DebugType rtype, DebugType atype, DebugType classtype, DebugType thistype)
    {
        this.rtype = rtype;
        this.atype = atype;
        this.classtype = classtype;
        this.thistype = thistype;
    }
    override DebugTypeFunction copy()
    {
        return new DebugTypeFunction(rtype, atype, classtype, thistype);
    }
    DebugType resolve(DebugType[] types)
    {
        rtype = rtype.resolve(types);
        assert(atype);
        atype = atype.resolve(types);
        if (classtype) classtype = classtype.resolve(types);
        if (thistype) thistype = thistype.resolve(types);
        return this;
    }
}

class DebugTypeArray : DebugType
{
    DebugType etype;
    this(DebugType etype)
    {
        this.etype = etype;
    }
    override DebugTypeArray copy()
    {
        return new DebugTypeArray(etype);
    }
    DebugType resolve(DebugType[] types)
    {
        etype = etype.resolve(types);
        return this;
    }
}

class DebugTypeDArray : DebugType
{
    DebugType etype;
    this(DebugType etype)
    {
        this.etype = etype;
    }
    override DebugTypeDArray copy()
    {
        return new DebugTypeDArray(etype);
    }
    DebugType resolve(DebugType[] types)
    {
        etype = etype.resolve(types);
        return this;
    }
}

class DebugTypeList : DebugType
{
    DebugType[] types;
    this(DebugType[] types)
    {
        this.types = types;
    }
    override DebugTypeList copy()
    {
        return new DebugTypeList(types);
    }
    DebugType resolve(DebugType[] types)
    {
        foreach(ref t; this.types)
            t = t.resolve(types);
        return this;
    }
}

class DebugTypeStruct : DebugType
{
    immutable(ubyte)[] name;
    DebugType fields;
    this(immutable(ubyte)[] name, DebugType fields)
    {
        this.name = name;
        this.fields = fields;
    }
    override DebugTypeStruct copy()
    {
        return new DebugTypeStruct(name, fields);
    }
    DebugType resolve(DebugType[] types)
    {
        if (fields) fields = fields.resolve(types);
        return this;
    }
}

class DebugTypeClass : DebugType
{
    immutable(ubyte)[] name;
    DebugType fields;
    this(immutable(ubyte)[] name, DebugType fields)
    {
        this.name = name;
        this.fields = fields;
    }
    override DebugTypeClass copy()
    {
        return new DebugTypeClass(name, fields);
    }
    DebugType resolve(DebugType[] types)
    {
        if (fields) fields = fields.resolve(types);
        return this;
    }
}

class DebugTypeField : DebugType
{
    DebugType type;
    uint offset;
    immutable(ubyte)[] name;
    this(DebugType type, uint offset, immutable(ubyte)[] name)
    {
        this.type = type;
        this.offset = offset;
        this.name = name;
    }
    override DebugTypeField copy()
    {
        return new DebugTypeField(type, offset, name);
    }
    DebugType resolve(DebugType[] types)
    {
        type = type.resolve(types);
        return this;
    }
}

class DebugTypeIndex : DebugType
{
    ushort id;
    this(ushort id)
    {
        this.id = id;
    }
    override DebugTypeIndex copy()
    {
        assert(0);
    }
    override DebugType resolve(DebugType[] types)
    {
        assert(id <= types.length);
        assert(types[id], "Undefined type 0x" ~ to!string(id, 16));
        return types[id].addMod(modifiers);
    }
}

class DebugTypeMemberList : DebugType
{
    DebugType[] types;
    uint[] offsets;
    this(DebugType[] types, uint[] offsets)
    {
        this.types = types;
        this.offsets = offsets;
    }
    override DebugTypeMemberList copy()
    {
        assert(0);
    }
    override DebugType resolve(DebugType[] types)
    {
        foreach(ref t; this.types)
            t = t.resolve(types);
        return this;
    }
}

class DebugTypeVTBLShape : DebugType
{
    ubyte[] flags;
    this(ubyte[] flags)
    {
        this.flags = flags;
    }
    override DebugTypeVTBLShape copy()
    {
        assert(0);
    }
    override DebugType resolve(DebugType[] types)
    {
        return this;
    }
}

class DebugTypeBaseClass : DebugType
{
    DebugType ctype;
    ushort attr;
    this(DebugType ctype, ushort attr)
    {
        this.ctype = ctype;
        this.attr = attr;
    }
    override DebugTypeBaseClass copy()
    {
        assert(0);
    }
    override DebugType resolve(DebugType[] types)
    {
        ctype = ctype.resolve(types);
        return this;
    }
}

class DebugTypeEnumMember : DebugType
{
    immutable(ubyte)[] name;
    DebugValue value;
    ushort attr;
    this(immutable(ubyte)[] name, DebugValue value, ushort attr)
    {
        this.name = name;
        this.value = value;
        this.attr = attr;
    }
    override DebugTypeEnumMember copy()
    {
        assert(0);
    }
    override DebugType resolve(DebugType[] types)
    {
        return this;
    }
}

class DebugTypeEnum : DebugType
{
    immutable(ubyte)[] name;
    DebugType btype;
    DebugType mlist;
    ushort prop;
    this(immutable(ubyte)[] name, DebugType btype, DebugType mlist, ushort prop)
    {
        this.name = name;
        this.btype = btype;
        this.mlist = mlist;
        this.prop = prop;
    }
    override DebugTypeEnum copy()
    {
        assert(0);
    }
    override DebugType resolve(DebugType[] types)
    {
        btype = btype.resolve(types);
        mlist = mlist.resolve(types);
        return this;
    }
}

class DebugTypeNested : DebugType
{
    immutable(ubyte)[] name;
    DebugType ctype;
    this(immutable(ubyte)[] name, DebugType ctype)
    {
        this.name = name;
        this.ctype = ctype;
    }
    override DebugTypeNested copy()
    {
        assert(0);
    }
    DebugType resolve(DebugType[] types)
    {
        ctype = ctype.resolve(types);
        return this;
    }
}

///////////////////////////////////////

class DebugValue
{
    long intVal()
    {
        assert(0);
    }
    T as(T)()
    {
        T t = cast(T)intVal();
        assert(t == intVal);
        return t;
    }
    abstract string toString();
}

class DebugValueInt : DebugValue
{
    long v;
    this(long v)
    {
        this.v  = v;
    }
    override long intVal()
    {
        return v;
    }
    override string toString()
    {
        return to!string(v);
    }
}
