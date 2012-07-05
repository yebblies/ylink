
import std.exception;
import std.conv;
import std.stdio;

import datafile;
import omfrecord;
import objectfile;
import symboltable;

public:

class OmfObjectFile : ObjectFile
{
private:
    DataFile f;
public:
    this(DataFile f)
    {
        this.f = f;
    }
    override void dump()
    {
        writeln("OMF Object file: ", f.filename);
        f.seek(0);
        while (!f.empty)
        {
            auto r = loadRecord();
            r.dump();
        }
    }
    override void loadSymbols(SymbolTable tab)
    {
        immutable(ubyte)[][] sourcefiles;
        immutable(ubyte)[][] names;

        f.seek(0);
        while (!f.empty)
        {
            auto r = loadRecord();
            switch(r.type)
            {
            case OmfRecordType.THEADR:
                auto len = r.data[0];
                enforce(len == r.data.length - 1, "Corrupt THEADR record");
                sourcefiles ~= r.data[1..$];
                break;
            case OmfRecordType.LNAMES:
                auto data = r.data;
                enforce(data.length != 0, "Empty LNAMES record");
                while (data.length != 0)
                {
                    auto len = data[0];
                    enforce(len + 1 <= data.length, "Name length too long");
                    names ~= data[1..1+len];
                    data = data[1+len..$];
                }
                break;
            case OmfRecordType.COMENT:
                enforce(r.data.length >= 2, "Corrupt COMENT record");
                auto ctype = r.data[0];
                auto cclass = r.data[1];
                switch(cclass)
                {
                case 0x9D:
                    foreach(c; r.data[2..$])
                    {
                        switch(c)
                        {
                        case 'A':
                            enforce(false, "68000 memory model is not supported");
                            break;
                        case 'B':
                            enforce(false, "68010 memory model is not supported");
                            break;
                        case 'C':
                            enforce(false, "68020 memory model is not supported");
                            break;
                        case 'D':
                            enforce(false, "68030 memory model is not supported");
                            break;
                        case '0':
                            enforce(false, "8086 memory model is not supported");
                            break;
                        case '1':
                            enforce(false, "80186 memory model is not supported");
                            break;
                        case '2':
                            enforce(false, "80286 memory model is not supported");
                            break;
                        case '3':
                            enforce(false, "80386 memory model is not supported");
                            break;
                        case '7':
                            // 786, apparently ok
                            break;
                        case 'O':
                            // We don't care about optimization
                            break;
                        case 's':
                            enforce(false, "small memory model is not supported");
                            break;
                        case 'm':
                            enforce(false, "medium memory model is not supported");
                            break;
                        case 'c':
                            enforce(false, "compact memory model is not supported");
                            break;
                        case 'l':
                            enforce(false, "large memory model is not supported");
                            break;
                        case 'h':
                            enforce(false, "huge memory model is not supported");
                            break;
                        case 'n':
                            // Windows NT memory model
                            break;
                        default:
                            enforce(false, "Corrupt COMENT record");
                        }
                    }
                    break;
                case 0xA1:
                    enforce(r.data.length == 5 &&
                            r.data[2] == 0x01 &&
                            r.data[3] == 'C' &&
                            r.data[4] == 'V',
                            "Only codeview debugging information is supported");
                    break;
                default:
                    assert(0);
                }
                break;
            case OmfRecordType.SEGDEF32:
                break;
            default:
                enforce(false, "Unsupported record type: " ~ to!string(r.type));
                break;
            }
        }
    }
private:
    OmfRecord loadRecord()
    {
        OmfRecord r;
        r.type = OmfRecord.recordType(f.readByte());
        r.data = f.readBytes(f.readWordLE())[0..$-1];
        return r;
    }
}
