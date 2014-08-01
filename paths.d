
import std.file;
import std.path;
import std.process;
import std.range;
import std.stdio;

import linker;

class Paths
{
    string[] paths;

    void add(string path)
    {
        if (path.length >= 2 &&
            path[0] == '"' &&
            path[$-1] == '"')
            path = path[1..$-1];
        paths ~= path;
        if (verbosity)
            writefln("verbose: Include Path \"%s\"", path);
    }
    void addLINK()
    {
        foreach(p; environment.get("LINK").split(";"))
            if (p)
                add(p);
    }
    bool search(ref string file)
    {
        foreach(path; paths)
        {
            auto p = buildPath(path, file);
            if (exists(p))
            {
                file = p;
                return true;
            }
        }
        return false;
    }
}
