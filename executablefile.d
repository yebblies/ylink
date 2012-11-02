
import std.stdio;

import debuginfo;

abstract class ExecutableFile
{
private:
    string name;
public:
    this(string name)
    {
        this.name = name;
    }
    void dump();
    void loadData();
    void loadDebugInfo(DebugInfo di);
}
