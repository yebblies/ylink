
/*
__gshared int global_shared = 0x12345678;
uint global_tls = 0x89898989;
extern int global_extern;

extern(C) extern int _imp__blah();
extern(C) extern int _imp__;

public void func()
{
    int[int] x;
    try {
    foreach(a, b; x) {}
    } catch {
    }
}

int main()
{
    __gshared int static_shared;
    static uint static_tls = 0x89898989;
    global_shared = global_tls + static_shared + static_tls;
    func();
    main();
    auto x = &main;
    auto a = 1;
    auto b = a + 1;
    auto c = a + b + 1;
    //_imp__ = _imp__blah();
    return c;
}*/

import std.stdio, std.conv, std.typetuple;

void main(string[] args)
{
    foreach(T; TypeTuple!(char, wchar, dchar, bool, byte, ubyte, short, ushort, int, uint, long, ulong, float, double, real, ifloat, idouble, ireal, cfloat, cdouble, creal))
    {
        T a;
        const T b;
        immutable T c;
        T* d;
        const(T)* e;
        immutable(T)* f;
        const(T*) g;
        immutable(T*) h;
    }

    try
    {
        auto x = to!int(args[1]);
        writeln(x);
    }
    catch
    {
       writeln("Or not...");
    }
}
