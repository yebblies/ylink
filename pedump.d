
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
    auto of = args.length == 4 ? File(args[3], "w") : stdout;
    auto f = new DataFile(args[1].defaultExtension("exe"));

    auto pe = new PEFile(f);
    pe.dump(of);
    pe.loadData();

    auto di = new DebugInfo();
    pe.loadDebugInfo(di);
}
