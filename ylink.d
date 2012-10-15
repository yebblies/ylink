
import std.exception;
import std.file;
import std.path;
import std.stdio;

import linker;
import objectfile;
import omfobjectfile;
import paths;
import pe;
import relocation;
import sectiontable;
import segment;
import symboltable;
import workqueue;

void main(string[] args)
{
    bool dump;
    bool map;
    string[] objectFilenames;
    Paths paths = new Paths();
    paths.add(".");
    paths.addLINK();
    string outputfile;

    for (auto i = 1; i < args.length; i++)
    {
        switch(args[i])
        {
        case "-o":
            i++;
            if (i < args.length)
                outputfile = args[i];
            break;
        case "-d":
            dump = true;
            break;
        case "-m":
            map = true;
            break;
        default:
            switch(extension(args[i]))
            {
            case ".obj":
                if (!outputfile.length)
                    outputfile = args[i].setExtension("exe");
            case ".lib":
                objectFilenames ~= args[i];
                break;
            default:
                enforce(false, "Unknown file type: '" ~ args[i] ~ "'");
                break;
            }
            break;
        }
    }

    auto queue = new WorkQueue!string();
    foreach(filename; objectFilenames)
        queue.append(defaultExtension(filename, "obj"));

    auto sectab = new SectionTable();
    auto symtab = new SymbolTable(null);
    auto objects = new WorkQueue!ObjectFile();
    while (!queue.empty())
    {
        auto filename = queue.pop();
        enforce(paths.search(filename), "File not found: " ~ filename);
        auto object = ObjectFile.detectFormat(filename);
        enforce(object, "Unknown object file format: " ~ filename);
        object.loadSymbols(symtab, sectab, queue, objects);
    }
    symtab.defineImports(sectab);
    symtab.allocateComdef(sectab);
    symtab.defineSpecial(sectab);
    symtab.checkUnresolved();
    auto segments = sectab.allocateSegments(imageBase, segAlign, fileAlign);
    symtab.buildImports(segments[SegmentType.Import].data);
    if (dump)
    {
        sectab.dump();
        symtab.dump();
        foreach(seg; segments)
            seg.dump();
    }
    while (!objects.empty())
    {
        auto object = objects.pop();
        object.loadData((SegmentType.TLS in segments) ? segments[SegmentType.TLS].base : -1);
    }
    buildPE(outputfile, segments, symtab);
    writeln("Success!");
    if (map)
        symtab.makeMap(outputfile.setExtension("map"));
}
