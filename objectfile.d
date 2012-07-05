
import datafile;
import omfobjectfile;

abstract class ObjectFile
{
    static ObjectFile detectFormat(string filename)
    {
        auto f = new DataFile(filename);
        switch(f.peekByte())
        {
        case 0x80:
            return new OmfObjectFile(f);
        default:
            return null;
        }
    }
    abstract void dump();
}
