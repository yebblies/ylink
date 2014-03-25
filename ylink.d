
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
import driver;

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
            default:
                args[i] = args[i].defaultExtension("obj");
                goto case;
            case ".obj":
                if (!outputfile.length)
                    outputfile = args[i].setExtension("exe");
                goto case;
            case ".lib":
                objectFilenames ~= args[i].defaultExtension("obj");
                break;
            }
            break;
        }
    }

    auto sectab = new SectionTable();
    auto symtab = new SymbolTable(null);
    auto objects = loadObjects(objectFilenames, paths, symtab, sectab);
    finalizeLoad(symtab, sectab);
    auto segments = generateSegments(objects, symtab, sectab);

    if (dump)
    {
        sectab.dump();
        symtab.dump();
        foreach(seg; segments)
            seg.dump();
    }

    buildPE(outputfile, segments, symtab);
    if (map)
        symtab.makeMap(outputfile.setExtension("map"));
}
