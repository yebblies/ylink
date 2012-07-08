
import std.exception;
import std.stdio;

import datafile;
import objectfile;
import omfdef;
import omfobjectfile;
import section;
import sectiontable;
import symbol;
import symboltable;
import workqueue;

final class OmfLibraryFile : ObjectFile
{
private:
    DataFile f;
    //size_t[] modules;
    uint[immutable(ubyte)[]] symbols;
public:
    this(DataFile f)
    {
        super(f.filename);
        this.f = f;
    }
    override void dump()
    {
        writeln("OMF Library file: ", f.filename);
        f.seek(0);
    }
    override void loadSymbols(SymbolTable symtab, SectionTable sectab, WorkQueue!string queue, WorkQueue!ObjectFile objects)
    {
        //writeln("OMF Library file: ", f.filename);
        //symtab.dumpUndefined();
        if (!symtab.hasUndefined())
            return;

        f.seek(0);
        enforce(f.peekByte() == 0xF0, "First record must be LHEADR");
        enforce(!f.empty(), "Library is empty");
        auto header = loadRecord();
        auto pagesize = header.data.length + 3 + 1;
        enforce(!(pagesize & (pagesize-1)), "block size must be a power of two");
        auto hdata = header.data;
        auto dict = getDwordLE(hdata);
        auto dictsize = getWordLE(hdata);
        enforce(getByte(hdata) == 0x01, "Library must be case sensitive");

        /*while (!f.empty() && f.peekByte() != 0xF1)
        {
            auto r = loadRecord();
            enforce(r.type == OmfRecordType.THEADR, "Unexpected record found in library");
            modules ~= f.tell() - r.data.length - 3;

            do
            {
                r = loadRecord();
            } while(r.type != OmfRecordType.MODEND16 && r.type != OmfRecordType.MODEND32);
            f.seek((f.tell() + pagesize - 1) & ~(pagesize - 1));
        }*/

        if (symbols == null)
        {
            f.seek(dict);
            foreach(i; 0..dictsize)
            {
                auto block = f.readBytes(512);
                foreach(j; 0..37)
                {
                    if (block[j])
                    {
                        auto pos = block[j]*2;
                        uint len = block[pos];
                        auto name = block[pos+1..pos+1+len];
                        auto page = block[pos+1+len] | (block[pos+1+len+1] << 8);
                        symbols[name] = page;
                    }
                }
            }
        }

        bool progress;
        do
        {
            progress = false;
            foreach(sym; symtab.undefined)
            {
                if (sym.name in symbols)
                {
                    auto page = symbols[sym.name];
                    auto obj = new OmfObjectFile(new DataFile(f, page * pagesize));
                    //writeln("Pulling in object ", page, " due to undefined symbol: ", cast(string)sym.name);
                    obj.loadSymbols(symtab, sectab, queue, objects);
                    progress = true;
                    break;
                }
            }
        }
        while (progress && symtab.hasUndefined());
    }
    override void loadData()
    {
        assert(0, "Libraries can't be loaded like this");
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
