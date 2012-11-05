
import std.array;
import std.stdio;
import std.conv;
import std.string;
import std.file;
import std.path;

import codeview;
import coffdef;
import datafile;
import debuginfo;
import pefile;

void main(string[] args)
{
    assert(args.length == 2 || args.length == 4 && args[2] == "-of");
    if (args.length == 4)
        stdout = File(args[3], "w");
    auto f = new DataFile(args[1].defaultExtension("exe"));

    auto pe = new PEFile(f);
    pe.dump();
    pe.loadData();
    pe.dumpImports();

    auto di = new DebugInfo();
    pe.loadDebugInfo(di);

    di.dump();
}
