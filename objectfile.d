
import datafile;
import modules;
import omflibraryfile;
import omfobjectfile;
import cofflibraryfile;
import coffobjectfile;
import sectiontable;
import symboltable;
import workqueue;

abstract class ObjectFile : Module
{
    this(string name)
    {
        super(name);
    }

    static ObjectFile detectFormat(DataFile f)
    {
        switch(f.peekByte())
        {
        case 0x80:
            return new OmfObjectFile(f);
        case 0xF0:
            return new OmfLibraryFile(f);
        case 0x4C:
            return new CoffObjectFile(f);
        case 0x00:
            return new CoffImportFile(f);
        case 0x21:
            return new CoffLibraryFile(f);
        default:
            return null;
        }
    }
    abstract void dump();
    abstract void loadSymbols(SymbolTable symtab, SectionTable segtab, WorkQueue!string queue, WorkQueue!ObjectFile objects);
    abstract void loadData(uint tlsBase);
}
