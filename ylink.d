
import std.exception;
import std.path;
import std.stdio;

import objectfile;
import omfobjectfile;
import relocation;
import symboltable;

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
                objectFilenames ~= s;
                break;
            default:
                enforce(false, "Unknown file type: '" ~ s ~ "'");
                break;
            }
            break;
        }
    }

    ObjectFile[] objectFiles;

    foreach(filename; objectFilenames)
    {
        objectFiles ~= ObjectFile.detectFormat(filename);
    }

    foreach(object; objectFiles)
    {
        object.dump();
    }
}
