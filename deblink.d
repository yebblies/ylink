
import std.algorithm;
import std.conv;
import std.file;
import std.string;
import std.exception;
import std.process;
import std.stdio;

import windebug;

import x86dis;

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

void main()
{
    STARTUPINFO si;
    PROCESS_INFORMATION pi0;
    PROCESS_INFORMATION pi1;
    HANDLE[DWORD] threads;
    HANDLE[DWORD] processes;
    bool[DWORD] firstException;
    int processCount;
    File*[DWORD] output;
    ubyte[DWORD] replaced;

    enforce(CreateProcessA("testd.exe", null, null, null, false, DEBUG_PROCESS | DEBUG_ONLY_THIS_PROCESS, null, null, &si, &pi0));
    threads[pi0.dwThreadId] = pi0.hThread;
    processes[pi0.dwProcessId] = pi0.hProcess;
    firstException[pi0.dwProcessId] = true;
    processCount++;
    output[pi0.dwProcessId] = new File("p0.txt", "wb");

    if (1)
    {
        enforce(CreateProcessA("teste.exe", null, null, null, false, DEBUG_PROCESS | DEBUG_ONLY_THIS_PROCESS, null, null, &si, &pi1));
        threads[pi1.dwThreadId] = pi1.hThread;
        processes[pi1.dwProcessId] = pi1.hProcess;
        firstException[pi1.dwProcessId] = true;
        processCount++;
        output[pi1.dwProcessId] = new File("p1.txt", "wb");
    }

    //ResumeThread(pi0.hThread);
    //ResumeThread(pi1.hThread);

    while(processCount)
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
                    if (firstException[de.dwProcessId])
                    {
                        firstException[de.dwProcessId] = false;
                        // First breakpoint, somewhere in kernel land
                        auto entrypoint = getStartAddress(processes[de.dwProcessId]);
                        //writefln("Entry point found at %.8X", entrypoint);
                        ubyte rep;
                        assert(ReadProcessMemory(processes[de.dwProcessId], entrypoint, &rep, 1, null));
                        replaced[de.dwProcessId] = rep;
                        rep = 0xCC;
                        assert(WriteProcessMemory(processes[de.dwProcessId], entrypoint, &rep, 1, null));
                    }
                    else
                    {
                        // Second one, we placed it at the beginning of the program
                        //writefln("Removed from: %.8X", de.Exception.ExceptionRecord.ExceptionAddress);
                        ubyte rep = replaced[de.dwProcessId];
                        assert(WriteProcessMemory(processes[de.dwProcessId], de.Exception.ExceptionRecord.ExceptionAddress, &rep, 1, null));
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
                    auto fh = output[de.dwProcessId];
                    //fh.writeln("Breakpoint in process ", de.dwProcessId);
                    CONTEXT context;
                    context.ContextFlags = CONTEXT_FULL;
                    enforce(GetThreadContext(hThread, &context), to!string(GetLastError()));
                    context.EFlags |= 0x100;
                    enforce(SetThreadContext(hThread, &context));
                    //fh.rawWrite((&context.Edi)[0..12]);
                    ubyte[16] inst;
                    auto addr = de.Exception.ExceptionRecord.ExceptionAddress;
                    ReadProcessMemory(processes[de.dwProcessId], addr, inst.ptr, 16, null);
                    //fh.writefln("%.8X: %s (%s+0x%X)", addr, X86Disassemble(inst.ptr), func, cast(uint)addr-p);
                    fh.writefln("%.8X %(%.2X%)", addr, inst[]);
                    //fh.writeln(X86Disassemble(inst.ptr));
                    //fh.rawWrite(inst[0..1]);
                    //fh.writefln("Breakpoint EIP: %.8X ESP: %.8X EBP: %.8X", context.Eip, context.Esp, context.Ebp);
                    //fh.writefln("           EAX: %.8X EBX: %.8X ECX: %.8X EDX: %.8X", context.Eax, context.Ebx, context.Ecx, context.Edx);
                    //fh.writefln("        EFLAGS: %.8X ESI: %.8X EDI: %.8X", context.EFlags, context.Esi, context.Edi);
                    break;
                default:
                    cont = DBG_EXCEPTION_NOT_HANDLED;
                    auto fh = output[de.dwProcessId];
                    auto addr = de.Exception.ExceptionRecord.ExceptionAddress;
                    auto code = de.Exception.ExceptionRecord.ExceptionCode;
                    ubyte[16] inst;
                    ReadProcessMemory(processes[de.dwProcessId], addr, inst.ptr, 16, null);
                    fh.writefln("%.8X %(%.2X%) %s %.8X", addr, inst[], "__Unknown_Exception__", cast(uint)code);
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
                processCount--;
                output[de.dwProcessId].close();
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
