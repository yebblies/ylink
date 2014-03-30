
import std.path;

import workqueue;

class Directive
{
    this()
    {
    }
    void apply(WorkQueue!string queue)
    {
        assert(0);
    }
}

class LibDirective : Directive
{
    immutable(ubyte)[] name;
    this(immutable(ubyte)[] name)
    {
        this.name = name;
    }
    override void apply(WorkQueue!string queue)
    {
        queue.append(defaultExtension(cast(string)name, "lib"));
    }
}

class NoLibDirective : Directive
{
    immutable(ubyte)[] name;
    this(immutable(ubyte)[] name)
    {
        this.name = name;
    }
    override void apply(WorkQueue!string queue)
    {
    }
}
