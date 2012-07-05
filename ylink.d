
import std.exception;
import std.path;
import std.stdio;

import objectfile;
import omfobjectfile;
import relocation;
import segmenttable;
import symboltable;
import workqueue;

void main(string[] args)
{
    bool dump;
    string[] objectFilenames;

    foreach(s; args[1..$])
    {
        switch(s)
        {
        case "-d":
            dump = true;
            break;
        default:
            switch(extension(s))
            {
            case ".obj":
            case ".lib":
                objectFilenames ~= s;
                break;
            default:
                enforce(false, "Unknown file type: '" ~ s ~ "'");
                break;
            }
            break;
        }
    }

    auto queue = new WorkQueue!string();
    foreach(filename; objectFilenames)
        queue.append(filename);

    auto segtab = new SegmentTable();
    auto symtab = new SymbolTable();
    auto objects = new WorkQueue!ObjectFile();
    while (!queue.empty())
    {
        auto filename = queue.pop();
        auto object = ObjectFile.detectFormat(filename);
        enforce(object, "Invalid or missing object file: " ~ filename);
        object.loadSymbols(symtab, segtab, queue, objects);
    }
    segtab.dump();
    symtab.dump();
}
