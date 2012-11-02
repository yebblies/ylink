
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
    abstract void toString(scope void delegate(const(char)[]) sink) const;
    void modToString(scope void delegate(const(char)[]) sink) const
    {
        if (modifiers & M_CONST) sink(" const");
        if (modifiers & M_VOLATILE) sink(" volatile");
        if (modifiers & M_UNALIGNED) sink(" unaligned");
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
    BT_CLONG,
    BT_CULONG,
    BT_LONG,
    BT_ULONG,
    BT_FLOAT,
    BT_DOUBLE,
    BT_REAL,
    BT_CFLOAT,
    BT_CDOUBLE,
    BT_CREAL,
}

immutable basicNames =
[
    "void",
    "char",
    "wchar",
    "dchar",
    "bool",
    "byte",
    "ubyte",
    "short",
    "ushort",
    "int",
    "uint",
    "c_long",
    "c_ulong",
    "long",
    "ulong",
    "float",
    "double",
    "real",
    "cfloat",
    "cdouble",
    "creal",
];

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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink(basicNames[bt]);
        modToString(sink);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        ntype.toString(sink);
        sink("*");
        modToString(sink);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        ntype.toString(sink);
        sink("&");
        modToString(sink);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        rtype.toString(sink);
        sink(" function");
        atype.toString(sink);
        if (classtype)
        {
            sink(" class(");
            classtype.toString(sink);
            sink(")");
        }
        if (thistype)
        {
            sink(" this(");
            thistype.toString(sink);
            sink(")");
        }
        modToString(sink);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        etype.toString(sink);
        sink("[]");
        modToString(sink);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        etype.toString(sink);
        sink("[?]");
        modToString(sink);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("(");
        foreach(i, t; types)
        {
            t.toString(sink);
            if (i != types.length - 1)
                sink(", ");
        }
        sink(")");
        assert(!modifiers);
    }
}

class DebugTypeUnion : DebugType
{
    immutable(ubyte)[] name;
    DebugType fields;
    uint size;
    ushort prop;
    this(immutable(ubyte)[] name, DebugType fields, uint size, ushort prop)
    {
        this.name = name;
        this.fields = fields;
        this.size = size;
        this.prop = prop;
    }
    override DebugTypeUnion copy()
    {
        return new DebugTypeUnion(name, fields, size, prop);
    }
    DebugType resolve(DebugType[] types)
    {
        if (fields) fields = fields.resolve(types);
        return this;
    }
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("union ");
        sink(cast(string)name);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink(cast(string)name);
        modToString(sink);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink(cast(string)name);
        modToString(sink);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("field(");
        sink(cast(string)name);
        sink(", ");
        type.toString(sink);
        sink(", +");
        sink(to!string(offset));
        sink(")");
        modToString(sink);
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
        if (id >= types.length || !types[id])
        {
            return new DebugTypeError(id);
        }
        //assert(id < types.length);
        ///assert(types[id], "Undefined type 0x" ~ to!string(id, 16));
        return types[id].addMod(modifiers);
    }
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        assert(0);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("(");
        foreach(i, t; types)
        {
            t.toString(sink);
            if (i != types.length + 1)
                sink(" ");
        }
        sink(")");
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("VTBL(");
        foreach(i, f; flags)
        {
            sink(to!string(f, 16));
            if (i != flags.length - 1)
                sink(", ");
        }
        sink(")");
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("BaseClass(");
        ctype.toString(sink);
        sink(", ");
        sink(to!string(attr, 16));
        sink(")");
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("enum(");
        sink(cast(string)name);
        sink(" = ");
        value.toString(sink);
        sink(")");
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("enum ");
        sink(cast(string)name);
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("Nested(");
        sink(cast(string)name);
        sink(", ");
        ctype.toString(sink);
        sink(")");
    }
}

class DebugTypeBitfield : DebugType
{
    DebugType ftype;
    ubyte pos;
    ubyte len;
    this(DebugType ftype, ubyte pos, ubyte len)
    {
        this.ftype = ftype;
        this.pos = pos;
        this.len = len;
    }
    override DebugTypeBitfield copy()
    {
        assert(0);
    }
    DebugType resolve(DebugType[] types)
    {
        ftype = ftype.resolve(types);
        return this;
    }
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("Bitfield(");
        ftype.toString(sink);
        sink(", +");
        sink(to!string(pos, 16));
        sink(", ");
        sink(to!string(len, 16));
        sink(")");
    }
}

class DebugTypeError : DebugType
{
    ushort id;
    this(ushort id)
    {
        this.id = id;
    }
    override DebugTypeError copy()
    {
        assert(0);
    }
    DebugType resolve(DebugType[] types)
    {
        return this;
    }
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink("__ERROR__(");
        sink(to!string(id, 16));
        sink(")");
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
    abstract void toString(scope void delegate(const(char)[]) sink) const;
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
    override void toString(scope void delegate(const(char)[]) sink) const
    {
        sink(to!string(v));
    }
}
