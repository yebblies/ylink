
import datafile;
import modules;
import omflibraryfile;
import omfobjectfile;
import segmenttable;
import symboltable;
import workqueue;

abstract class ObjectFile : Module
{
    this(string name)
    {
        super(name);
    }

    static ObjectFile detectFormat(string filename)
    {
        auto f = new DataFile(filename);
        switch(f.peekByte())
        {
        case 0x80:
            return new OmfObjectFile(f);
        case 0xF0:
            return new OmfLibraryFile(f);
        default:
            return null;
        }
    }
    abstract void dump();
    abstract void loadSymbols(SymbolTable symtab, SegmentTable segtab, WorkQueue!string queue, WorkQueue!ObjectFile objects);
}
