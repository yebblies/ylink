
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
}

enum
{
    BT_VOID,
    BT_CHAR,
    BT_DCHAR,
    BT_BOOL,
    BT_INT,
    BT_UINT,
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
}

class DebugTypeFunction : DebugType
{
    DebugType rtype;
    DebugType atype;
    this(DebugType rtype, DebugType atype)
    {
        this.rtype = rtype;
        this.atype = atype;
    }
    override DebugTypeFunction copy()
    {
        return new DebugTypeFunction(rtype, atype);
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
}

class DebugTypeError : DebugType
{
    this()
    {
    }
    override DebugTypeError copy()
    {
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
}
