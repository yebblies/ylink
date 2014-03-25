
import std.exception;
import std.stdio;

import relocation;
import sectiontable;
import segment;
import symboltable;
import workqueue;
import objectfile;
import linker;
import paths;

WorkQueue!ObjectFile loadObjects(string[] objFilenames, Paths paths, SymbolTable symtab, SectionTable sectab)
{
    auto queue = new WorkQueue!string();
    foreach(filename; objFilenames)
        queue.append(filename);

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
    return objects;
}

void finalizeLoad(SymbolTable symtab, SectionTable sectab)
{
    symtab.defineImports(sectab);
    symtab.allocateComdef(sectab);
    symtab.defineSpecial(sectab, imageBase);
    symtab.checkUnresolved();
}

Segment[SegmentType] generateSegments(WorkQueue!ObjectFile objects, SymbolTable symtab, SectionTable sectab)
{
    auto segments = sectab.allocateSegments(imageBase, segAlign, fileAlign);
    symtab.buildImports(segments[SegmentType.Import].data, imageBase);

    while (!objects.empty())
    {
        auto object = objects.pop();
        object.loadData((SegmentType.TLS in segments) ? segments[SegmentType.TLS].base : -1);
    }
    return segments;
}
