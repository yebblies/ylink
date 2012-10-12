
import std.conv;
import std.exception;
import std.process;
import std.stdio;

import windebug;

import x86dis;

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
                        goto case EXCEPTION_SINGLE_STEP;
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
                    ubyte[64] inst;
                    ReadProcessMemory(processes[de.dwProcessId], de.Exception.ExceptionRecord.ExceptionAddress, inst.ptr, 64, null);
                    fh.writeln(X86Disassemble(inst.ptr));
                    //fh.rawWrite(inst[0..1]);
                    //fh.writefln("Breakpoint EIP: %.8X ESP: %.8X EBP: %.8X", context.Eip, context.Esp, context.Ebp);
                    //fh.writefln("           EAX: %.8X EBX: %.8X ECX: %.8X EDX: %.8X", context.Eax, context.Ebx, context.Ecx, context.Edx);
                    //fh.writefln("        EFLAGS: %.8X ESI: %.8X EDI: %.8X", context.EFlags, context.Esi, context.Edi);
                    break;
                default:
                    cont = DBG_EXCEPTION_NOT_HANDLED;
                    output[de.dwProcessId].writefln("Unknown exception 0x%.8X", de.Exception.ExceptionRecord.ExceptionCode);
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
