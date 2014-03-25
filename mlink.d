
import std.algorithm;
import std.array;
import std.exception;
import std.file;
import std.path;
import std.stdio;
import std.string;

import linker;
import paths;
import driver;
import pe;
import sectiontable;
import symboltable;
import coffobjectfile : parseMSLinkerSwitch;

void main(string[] args)
{
    bool map;

    string[] objFilenames;
    string outFilename;
    string mapFilename;

    Paths paths = new Paths();
    paths.add(".");
    paths.addLINK();

    foreach(i, s; args[1..$])
    {
        //writeln("arg: ", arg);
        while (s.length)
        {
            string arg;
            string val;
            if (!parseMSLinkerSwitch(s, arg, val, true))
            {
                enforce(s[0] != '/', "Invalid linker command line: " ~ args[i+1]);
                objFilenames ~= s;
                s = null;
                break;
            }

            switch(arg)
            {
            case "/MAP":
                assert(!map, "Can only specify one map filename");
                map = true;
                if (val.length)
                    mapFilename = val;
                break;
            case "/OUT":
                assert(!outFilename.length, "Can only specify one output filename");
                assert(val.length, "Invalid output filename");
                outFilename = val;
                break;
            case "/LIBPATH":
                assert(val.length, "Invalid library path");
                paths.add(val);
                break;
            default:
                enforce(0, "Unknown linker directive: " ~ arg ~ ":" ~ val);
            }
        }
    }

    assert(objFilenames.length, "Must specify at least one object file");
    foreach(ref f; objFilenames)
        f = f.defaultExtension("obj");

    if (outFilename.length)
        outFilename = outFilename.defaultExtension("exe");
    else
        outFilename = outFilename.baseName().setExtension("exe");

    if (mapFilename.length)
        mapFilename = mapFilename.defaultExtension("map");
    else
        mapFilename = outFilename.setExtension("map");

    auto sectab = new SectionTable();
    auto symtab = new SymbolTable(null);
    symtab.entryPoint = cast(immutable(ubyte)[])"mainCRTStartup";
    auto objects = loadObjects(objFilenames, paths, symtab, sectab);
    finalizeLoad(symtab, sectab);
    auto segments = generateSegments(objects, symtab, sectab);

    if (false)
    {
        sectab.dump();
        symtab.dump();
        foreach(seg; segments)
            seg.dump();
    }

    buildPE(outFilename, segments, symtab);
    if (map)
        symtab.makeMap(mapFilename);
}
