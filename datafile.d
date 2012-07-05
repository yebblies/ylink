
import std.file;
import std.stdio;

class DataFile
{
    string filename;
private:
    immutable(ubyte)[] data;
    size_t pos;
public:
    this(string filename)
    {
        this.filename = filename;
        this.data = cast(immutable(ubyte)[])read(filename);
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
        return d[0] | (d[1] << 8);
    }
    bool empty()
    {
        return pos == data.length;
    }
    void seek(size_t pos)
    {
        this.pos = pos;
    }
    immutable(ubyte)[] readBytes(size_t n)
    {
        auto d = data[pos..pos+n];
        pos += n;
        return d;
    }
}
