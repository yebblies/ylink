
import std.file;
import std.stdio;

final class DataFile
{
    string filename;
private:
    immutable(ubyte)[] data;
    size_t pos;
public:
    this(string filename)
    {
        this.filename = filename;
        this.data = cast(immutable(ubyte)[]).read(filename);
    }
    this(DataFile other, size_t start)
    {
        this.filename = other.filename;
        this.data = other.data[start..$];
    }
    ubyte peekByte()
    {
        return data[pos];
    }
    ubyte readByte()
    {
        return data[pos++];
    }
    ushort readWordLE()
    {
        auto d = data[pos..pos+2];
        pos += 2;
        return getWordLE(d);;
    }
    uint readDwordLE()
    {
        auto d = data[pos..pos+4];
        pos += 4;
        return getDwordLE(d);
    }
    T read(T)()
    {
        auto d = data[pos..pos+T.sizeof];
        pos += T.sizeof;
        return (cast(T[])d)[0];
    }
    bool empty()
    {
        return pos == data.length;
    }
    void seek(size_t pos)
    {
        this.pos = pos;
    }
    size_t tell()
    {
        return pos;
    }
    void alignto(size_t num)
    {
        pos += num-1;
        pos &= ~(num-1);
    }
    immutable(ubyte)[] readBytes(size_t n)
    {
        auto d = data[pos..pos+n];
        pos += n;
        return d;
    }
}

ubyte getByte(ref immutable(ubyte)[] d)
{
    ubyte r = d[0];
    d = d[1..$];
    return r;
}

ushort getWordLE(ref immutable(ubyte)[] d)
{
    ushort r = d[0] | (d[1] << 8);
    d = d[2..$];
    return r;
}

ushort getWordBE(ref immutable(ubyte)[] d)
{
    ushort r = d[1] | (d[0] << 8);
    d = d[2..$];
    return r;
}

uint getDwordLE(ref immutable(ubyte)[] d)
{
    uint r = d[0] | (d[1] << 8) | (d[2] << 16) | (d[3] << 24);
    d = d[4..$];
    return r;
}

immutable(ubyte)[] getBytes(ref immutable(ubyte)[] d, size_t n)
{
    immutable(ubyte)[] r = d[0..n];
    d = d[n..$];
    return r;
}
