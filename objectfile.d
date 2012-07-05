
import std.file;

import datafile;
import omfobjectfile;
import segmenttable;
import symboltable;
import workqueue;

abstract class ObjectFile
{
    string name;

    this(string name)
    {
        this.name = name;
    }

    static ObjectFile detectFormat(string filename)
    {
        if (!exists(filename))
            return null;
        auto f = new DataFile(filename);
        switch(f.peekByte())
        {
        case 0x80:
            return new OmfObjectFile(f);
        case 0xF0:
            //return new OmfLibraryFile(f);
            return null;
        default:
            return null;
        }
    }
    abstract void dump();
    abstract void loadSymbols(SymbolTable symtab, SegmentTable segtab, WorkQueue!string queue, WorkQueue!ObjectFile objects);
}
