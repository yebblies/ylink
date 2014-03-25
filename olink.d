
import std.algorithm;
import std.array;
import std.exception;
import std.file;
import std.path;
import std.stdio;
import std.string;

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
    bool map;
    bool dump;
    bool codeview;

    string[][] files;

    string[] objFilenames;
    string outFilename;
    string mapFilename;
    string defFilename;
    string[] resFilenames;

    Paths paths = new Paths();
    paths.add(".");
    paths.addLINK();

    size_t parseSwitch(string arg)
    {
        assert(arg[0] == '/');
        auto i = 1;
        while (i < arg.length && arg[i] != '/' && arg[i] != ' ' && arg[i] != ';')
            i++;
        if (!icmp(arg[0..i], "/MAP") || !icmp(arg[0..i], "/M"))
        {
            map = true;
        } else if (!icmp(arg[0..i], "/CO"))
        {
            codeview = true;
        } else if (!icmp(arg[0..i], "/NOI"))
        {
        } else if (!icmp(arg[0..i], "/DUMP"))
        {
            dump = true;
        } else
        {
            assert(0, "Unrecognised switch: " ~ arg[0..i]);
        }
        if (i < arg.length && arg[i] == ';')
            i++;
        return i;
    }

    foreach(arg; args[1..$])
    {
        //writeln("arg: ", arg);
        auto i = 0;
        if (arg[i] != '/' && files.length == 0)
        {
            auto start = i;
            string[] current;
            do
            {
                if (i != start && (arg[i] == '/' || arg[i] == '+' || arg[i] == ','))
                {
                    current ~= arg[start..i];
                    start = i+1;
                }
                if (arg[i] == '/' || arg[i] == ',')
                {
                    start = i+1;
                    files ~= current;
                    current = null;
                }
                if (arg[i] == '/')
                    break;
                i++;
            } while (i < arg.length);
            if (i != start && i == arg.length)
                current ~= arg[start..i];
            if (current.length)
                files ~= current;
        }
        while (i < arg.length && arg[i] == '/')
            i += parseSwitch(arg[i..$]);
        assert(arg.length == i, "Unrecognised argument: " ~ arg[i..$]);
    }

    assert(files.length <= 6, "Too many parameters");
    files.length = 6;

    assert(files[0].length, "Must specify at least one object file");
    assert(files[1].length <= 1, "Can only specify one output filename");
    assert(files[2].length <= 1, "Can only specify one map filename");
    assert(files[4].length == 0, "ylink can't actually handle def files yet");
    assert(files[5].length == 0, "ylink can't actually handle res files yet");

    foreach(f; files[0])
        objFilenames ~= f.defaultExtension("obj");

    if (files[1].length)
        outFilename = files[1][0].defaultExtension("exe");
    else
        outFilename = files[0][0].baseName().setExtension("exe");

    if (files[2].length && !icmp(files[2][0].baseName().stripExtension(), "nul"))
        map = false;
    else if (files[2].length)
        mapFilename = files[2][0].defaultExtension("map");
    else
        mapFilename = outFilename.setExtension("map");

    foreach(f; files[3])
        objFilenames ~= f.defaultExtension("lib");

    if (files[4].length)
        defFilename = files[4][0].defaultExtension("def");
    else
        defFilename = outFilename.setExtension("def");

    foreach(f; files[5])
        resFilenames ~= f.defaultExtension("res");

    auto queue = new WorkQueue!string();
    foreach(filename; objFilenames)
        queue.append(filename);

    auto sectab = new SectionTable();
    auto symtab = new SymbolTable(null);
    auto objects = new WorkQueue!ObjectFile();
    while (!queue.empty())
    {
        auto filename = queue.pop();
        if (!paths.search(filename))
            writeln("Warning - File not found: " ~ filename);
        else
        {
            auto object = ObjectFile.detectFormat(filename);
            enforce(object, "Unknown object file format: " ~ filename);
            object.loadSymbols(symtab, sectab, queue, objects);
        }
    }
    symtab.defineImports(sectab);
    symtab.allocateComdef(sectab);
    symtab.defineSpecial(sectab, imageBase);
    if (!symtab.entryPoint.length)
        symtab.entryPoint = cast(immutable(ubyte)[])"mainCRTStartup";
    symtab.checkUnresolved();
    auto segments = sectab.allocateSegments(imageBase, segAlign, fileAlign);
    symtab.buildImports(segments[SegmentType.Import].data, imageBase);
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
    buildPE(outFilename, segments, symtab);
    if (map)
        symtab.makeMap(mapFilename);
}
