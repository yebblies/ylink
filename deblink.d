
import std.algorithm;
import std.conv;
import std.file;
import std.string;
import std.exception;
import std.process;
import std.stdio;

import windebug;

void* getStartAddress(HANDLE p)
{
    HMODULE[256] modules;
    DWORD n;
    assert(EnumProcessModules(p, modules.ptr, modules.length * HMODULE.sizeof, &n), to!string(GetLastError()));
    n /= HMODULE.sizeof;
    if (n > modules.length)
        n = modules.length;
    foreach(i, m; modules[0..n])
    {
        MODULEINFO mi;
        assert(GetModuleInformation(p, m, &mi, MODULEINFO.sizeof));
        if (mi.lpBaseOfDll == cast(void*)0x400000)
        {
            return mi.EntryPoint;
        }
    }
    assert(0);
}

void main(string[] args)
{
    assert(args.length == 2 || args.length == 4);
    auto of = stdout;
    if (args.length == 4)
    {
        assert(args[2] == "-of");
        of = File(args[3], "wb");
    }
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    HANDLE[DWORD] threads;
    HANDLE phandle;
    bool firstException;
    bool quit;
    ubyte replaced;

    enforce(CreateProcessA(toStringz(args[1]), null, null, null, false, DEBUG_PROCESS | DEBUG_ONLY_THIS_PROCESS, null, null, &si, &pi));
    threads[pi.dwThreadId] = pi.hThread;
    phandle = pi.hProcess;
    firstException = true;

    while(!quit)
    {
        DEBUG_EVENT de;
        if (WaitForDebugEvent(&de, INFINITE))
        {
            DWORD cont = DBG_CONTINUE;
            //writeln();
            //write(de.dwProcessId, ": ");
            switch(de.dwDebugEventCode)
            {
            case EXCEPTION_DEBUG_EVENT:
                //writeln("EXCEPTION_DEBUG_EVENT");
                switch(de.Exception.ExceptionRecord.ExceptionCode)
                {
                case EXCEPTION_BREAKPOINT:
                    //writeln("EXCEPTION_BREAKPOINT");
                    if (firstException)
                    {
                        firstException = false;
                        // First breakpoint, somewhere in kernel land
                        auto entrypoint = getStartAddress(phandle);
                        //writefln("Entry point found at %.8X", entrypoint);
                        ubyte rep;
                        assert(ReadProcessMemory(phandle, entrypoint, &rep, 1, null));
                        replaced = rep;
                        rep = 0xCC;
                        assert(WriteProcessMemory(phandle, entrypoint, &rep, 1, null));
                    }
                    else
                    {
                        // Second one, we placed it at the beginning of the program
                        //writefln("Removed from: %.8X", de.Exception.ExceptionRecord.ExceptionAddress);
                        ubyte rep = replaced;
                        assert(WriteProcessMemory(phandle, de.Exception.ExceptionRecord.ExceptionAddress, &rep, 1, null));
                        auto hThread = threads[de.dwThreadId];
                        CONTEXT context;
                        context.ContextFlags = CONTEXT_FULL;
                        enforce(GetThreadContext(hThread, &context), to!string(GetLastError()));
                        context.EFlags |= 0x100;
                        context.Eip--;
                        enforce(SetThreadContext(hThread, &context));
                    }
                    break;
                case EXCEPTION_SINGLE_STEP:
                    //writeln("EXCEPTION_SINGLE_STEP");
                    auto hThread = threads[de.dwThreadId];
                    //writeln("Breakpoint in process ", de.dwProcessId);
                    CONTEXT context;
                    context.ContextFlags = CONTEXT_FULL;
                    enforce(GetThreadContext(hThread, &context), to!string(GetLastError()));
                    context.EFlags |= 0x100;
                    enforce(SetThreadContext(hThread, &context));
                    //rawWrite((&context.Edi)[0..12]);
                    ubyte[16] inst;
                    auto addr = de.Exception.ExceptionRecord.ExceptionAddress;
                    ReadProcessMemory(phandle, addr, inst.ptr, 16, null);
                    //writefln("%.8X: %s (%s+0x%X)", addr, X86Disassemble(inst.ptr), func, cast(uint)addr-p);
                    of.writefln("%.8X %(%.2X%)", addr, inst[]);
                    //writeln(X86Disassemble(inst.ptr));
                    //rawWrite(inst[0..1]);
                    //writefln("Breakpoint EIP: %.8X ESP: %.8X EBP: %.8X", context.Eip, context.Esp, context.Ebp);
                    //writefln("           EAX: %.8X EBX: %.8X ECX: %.8X EDX: %.8X", context.Eax, context.Ebx, context.Ecx, context.Edx);
                    //writefln("        EFLAGS: %.8X ESI: %.8X EDI: %.8X", context.EFlags, context.Esi, context.Edi);
                    break;
                default:
                    cont = DBG_EXCEPTION_NOT_HANDLED;
                    auto addr = de.Exception.ExceptionRecord.ExceptionAddress;
                    auto code = de.Exception.ExceptionRecord.ExceptionCode;
                    ubyte[16] inst;
                    ReadProcessMemory(phandle, addr, inst.ptr, 16, null);
                    of.writefln("%.8X %(%.2X%) %s %.8X", cast(uint)addr, inst[], "__Unknown_Exception__", cast(uint)code);
                    break;
                }
                break;
            case CREATE_THREAD_DEBUG_EVENT:
                writeln("CREATE_THREAD_DEBUG_EVENT");
                break;
            case CREATE_PROCESS_DEBUG_EVENT:
                writeln("CREATE_PROCESS_DEBUG_EVENT");
                break;
            case EXIT_THREAD_DEBUG_EVENT:
                writeln("EXIT_THREAD_DEBUG_EVENT");
                break;
            case EXIT_PROCESS_DEBUG_EVENT:
                writeln("EXIT_PROCESS_DEBUG_EVENT");
                quit = true;
                break;
            case LOAD_DLL_DEBUG_EVENT:
                writeln("LOAD_DLL_DEBUG_EVENT");
                //de.LoadDll.lpImageName
                break;
            case UNLOAD_DLL_DEBUG_EVENT:
                writeln("UNLOAD_DLL_DEBUG_EVENT");
                break;
            case OUTPUT_DEBUG_STRING_EVENT:
                writeln("OUTPUT_DEBUG_STRING_EVENT");
                break;
            case RIP_EVENT:
                writeln("RIP_EVENT");
                break;
            default:
                assert(0);
            }
            ContinueDebugEvent(de.dwProcessId, de.dwThreadId, cont);
        }
        else
            assert(0);
    }

    //enforce(TerminateProcess(pi0.hProcess, 137));
    //enforce(TerminateProcess(pi1.hProcess, 137));
}
