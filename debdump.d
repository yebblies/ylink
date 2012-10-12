
import std.conv;
import std.exception;
import std.process;
import std.stdio;

import windebug;

void main()
{
    auto f0 = File("p0.txt", "rb");
    auto f1 = File("p1.txt", "rb");

    size_t count;
    while (!f0.eof())
    {
        CONTEXT context0;
        ubyte inst0;
        f0.rawRead((&context0.Edi)[0..12]);
        f0.rawRead((&inst0)[0..1]);
        CONTEXT context1;
        ubyte inst1;
        f1.rawRead((&context1.Edi)[0..12]);
        f1.rawRead((&inst1)[0..1]);
        if (inst0 != inst1)
        {
            writeln("Different at: ", count);
            writefln("   EIP: %.8X ESP: %.8X EBP: %.8X", context0.Eip, context0.Esp, context0.Ebp);
            writefln("   EAX: %.8X EBX: %.8X ECX: %.8X EDX: %.8X", context0.Eax, context0.Ebx, context0.Ecx, context0.Edx);
            writefln("EFLAGS: %.8X ESI: %.8X EDI: %.8X VAL: %.2X", context0.EFlags, context0.Esi, context0.Edi, inst0);
            writefln("   EIP: %.8X ESP: %.8X EBP: %.8X", context1.Eip, context1.Esp, context1.Ebp);
            writefln("   EAX: %.8X EBX: %.8X ECX: %.8X EDX: %.8X", context1.Eax, context1.Ebx, context1.Ecx, context1.Edx);
            writefln("EFLAGS: %.8X ESI: %.8X EDI: %.8X VAL: %.2X", context1.EFlags, context1.Esi, context1.Edi, inst1);
            return;
        }
        count++;
    }
}
