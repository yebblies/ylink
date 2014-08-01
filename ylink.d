
import std.exception;
import std.file;
import std.path;
import std.process;
import std.string;
import std.stdio;
import std.getopt;

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

void usage(string[] args)
{
    string program = (args == null || args.length <= 0) ? "ylink" : args[0];
    writefln("%s [options...] <object-files>...", baseName(program));
    writeln( "    -o<file> | --output<file>  Output file (default is the first .obj file with");
    writeln( "                               the .exe extension)");
    writeln( "    -L<path>              Path to include");
    writeln( "    -d | --dump           Dump the linker tables");
    writeln( "    -m | --map            Create map file");
    writeln( "    -v | --verbose        Set verbose output");
}
int main(string[] args)
{
    bool dump;
    bool map;
    string[] objectFilenames;
    string[] includePaths;
    string outputfile = null;

    getopt(args,
	   "o|output" , &outputfile,
	   "L"        , &includePaths,
	   "d|dump"   , &dump,
	   "m|map"    , &map,
	   "v|verbose", &verbosity);

    if (args.length <= 1)
    {
        usage(args);
        return 1;
    }

    string firstObjFile = null;
    for (auto i = 1; i < args.length; i++)
    {
        string file = args[i];
        switch (extension(file))
        {
        default:
            args[i] = args[i].defaultExtension("obj");
            goto case;
        case ".obj":
            if (firstObjFile == null)
                firstObjFile = args[i].setExtension("exe");
            goto case;
        case ".lib":
            objectFilenames ~= args[i].defaultExtension("obj");
            break;
        }
    }

    if (firstObjFile == null)
    {
        writeln("Error: you must provide at least one .obj file");
        usage(args);
        return 1;
    }

    if (outputfile == null)
        outputfile = firstObjFile;


    //
    // Add Include Paths
    //
    Paths paths = new Paths();
    paths.add(".");
    foreach (includePath; includePaths)
    {
        paths.add(includePath);
    }
    paths.addLINK();

    //
    // Add object filenames
    //
    auto sectab = new SectionTable();
    auto symtab = new SymbolTable(null);
    auto objects = loadObjects(objectFilenames, paths, symtab, sectab);

    finalizeLoad(symtab, sectab);

    auto segments = generateSegments(objects, symtab, sectab);

    if (dump)
    {
        sectab.dump();
        symtab.dump();
        foreach (seg; segments)
            seg.dump();
    }

    buildPE(outputfile, segments, symtab);
    if (map)
        symtab.makeMap(outputfile.setExtension("map"));

    return 0;
}
