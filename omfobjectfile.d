
import std.stdio;

import datafile;
import omfrecord;
import objectfile;

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
private:
    OmfRecord loadRecord()
    {
        OmfRecord r;
        r.type = OmfRecord.recordType(f.readByte());
        r.data = f.readBytes(f.readWordLE());
        return r;
    }
}
