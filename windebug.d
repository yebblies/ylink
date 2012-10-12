
public import core.sys.windows.windows;

extern(Windows) BOOL CreateProcessA(LPCTSTR lpApplicationName, LPTSTR lpCommandLine, LPSECURITY_ATTRIBUTES lpProcessAttributes, LPSECURITY_ATTRIBUTES lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment, LPCTSTR lpCurrentDirectory, LPSTARTUPINFO lpStartupInfo, LPPROCESS_INFORMATION lpProcessInformation);
extern(Windows) BOOL TerminateProcess(HANDLE hProcess, UINT uExitCode);
extern(Windows) BOOL WaitForDebugEvent(LPDEBUG_EVENT lpDebugEvent, DWORD dwMilliseconds);
extern(Windows) BOOL ContinueDebugEvent(DWORD dwProcessId, DWORD dwThreadId, DWORD dwContinueStatus);
extern(Windows) BOOL ReadProcessMemory(HANDLE hProcess, LPCVOID lpBaseAddress, LPVOID lpBuffer, SIZE_T nSize, SIZE_T *lpNumberOfBytesRead);

enum DBG_CONTINUE = 0x00010002;
enum DBG_EXCEPTION_NOT_HANDLED = 0x80010001;

enum EXCEPTION_DEBUG_EVENT = 1;
enum CREATE_THREAD_DEBUG_EVENT = 2;
enum CREATE_PROCESS_DEBUG_EVENT = 3;
enum EXIT_THREAD_DEBUG_EVENT = 4;
enum EXIT_PROCESS_DEBUG_EVENT = 5;
enum LOAD_DLL_DEBUG_EVENT = 6;
enum UNLOAD_DLL_DEBUG_EVENT = 7;
enum OUTPUT_DEBUG_STRING_EVENT = 8;
enum RIP_EVENT = 9;

struct STARTUPINFO
{
    DWORD  cb;
    LPTSTR lpReserved;
    LPTSTR lpDesktop;
    LPTSTR lpTitle;
    DWORD  dwX;
    DWORD  dwY;
    DWORD  dwXSize;
    DWORD  dwYSize;
    DWORD  dwXCountChars;
    DWORD  dwYCountChars;
    DWORD  dwFillAttribute;
    DWORD  dwFlags;
    WORD   wShowWindow;
    WORD   cbReserved2;
    LPBYTE lpReserved2;
    HANDLE hStdInput;
    HANDLE hStdOutput;
    HANDLE hStdError;
}
alias STARTUPINFO* LPSTARTUPINFO;

struct PROCESS_INFORMATION
{
    HANDLE hProcess;
    HANDLE hThread;
    DWORD  dwProcessId;
    DWORD  dwThreadId;
}
alias PROCESS_INFORMATION* LPPROCESS_INFORMATION;

enum CREATE_SUSPENDED = 0x00000004;
enum DEBUG_PROCESS = 0x00000001;
enum DEBUG_ONLY_THIS_PROCESS = 0x00000002;

struct DEBUG_EVENT
{
    DWORD dwDebugEventCode;
    DWORD dwProcessId;
    DWORD dwThreadId;
    union
    {
        EXCEPTION_DEBUG_INFO      Exception;
        CREATE_THREAD_DEBUG_INFO  CreateThread;
        CREATE_PROCESS_DEBUG_INFO CreateProcessInfo;
        EXIT_THREAD_DEBUG_INFO    ExitThread;
        EXIT_PROCESS_DEBUG_INFO   ExitProcess;
        LOAD_DLL_DEBUG_INFO       LoadDll;
        UNLOAD_DLL_DEBUG_INFO     UnloadDll;
        OUTPUT_DEBUG_STRING_INFO  DebugString;
        RIP_INFO                  RipInfo;
    }
}
alias DEBUG_EVENT* LPDEBUG_EVENT;

struct EXCEPTION_DEBUG_INFO
{
    EXCEPTION_RECORD ExceptionRecord;
    DWORD            dwFirstChance;
}
alias EXCEPTION_DEBUG_INFO* LPEXCEPTION_DEBUG_INFO;

struct EXCEPTION_RECORD
{
    DWORD                    ExceptionCode;
    DWORD                    ExceptionFlags;
    EXCEPTION_RECORD*        ExceptionRecord;
    PVOID                    ExceptionAddress;
    DWORD                    NumberParameters;
    ULONG_PTR[EXCEPTION_MAXIMUM_PARAMETERS] ExceptionInformation;
}
alias EXCEPTION_RECORD* PEXCEPTION_RECORD;

enum EXCEPTION_MAXIMUM_PARAMETERS = 15;

enum : DWORD {
        STATUS_WAIT_0                      = 0,
        STATUS_ABANDONED_WAIT_0            = 0x00000080,
        STATUS_USER_APC                    = 0x000000C0,
        STATUS_TIMEOUT                     = 0x00000102,
        STATUS_PENDING                     = 0x00000103,

        STATUS_SEGMENT_NOTIFICATION        = 0x40000005,
        STATUS_GUARD_PAGE_VIOLATION        = 0x80000001,
        STATUS_DATATYPE_MISALIGNMENT       = 0x80000002,
        STATUS_BREAKPOINT                  = 0x80000003,
        STATUS_SINGLE_STEP                 = 0x80000004,

        STATUS_ACCESS_VIOLATION            = 0xC0000005,
        STATUS_IN_PAGE_ERROR               = 0xC0000006,
        STATUS_INVALID_HANDLE              = 0xC0000008,

        STATUS_NO_MEMORY                   = 0xC0000017,
        STATUS_ILLEGAL_INSTRUCTION         = 0xC000001D,
        STATUS_NONCONTINUABLE_EXCEPTION    = 0xC0000025,
        STATUS_INVALID_DISPOSITION         = 0xC0000026,
        STATUS_ARRAY_BOUNDS_EXCEEDED       = 0xC000008C,
        STATUS_FLOAT_DENORMAL_OPERAND      = 0xC000008D,
        STATUS_FLOAT_DIVIDE_BY_ZERO        = 0xC000008E,
        STATUS_FLOAT_INEXACT_RESULT        = 0xC000008F,
        STATUS_FLOAT_INVALID_OPERATION     = 0xC0000090,
        STATUS_FLOAT_OVERFLOW              = 0xC0000091,
        STATUS_FLOAT_STACK_CHECK           = 0xC0000092,
        STATUS_FLOAT_UNDERFLOW             = 0xC0000093,
        STATUS_INTEGER_DIVIDE_BY_ZERO      = 0xC0000094,
        STATUS_INTEGER_OVERFLOW            = 0xC0000095,
        STATUS_PRIVILEGED_INSTRUCTION      = 0xC0000096,
        STATUS_STACK_OVERFLOW              = 0xC00000FD,
        STATUS_CONTROL_C_EXIT              = 0xC000013A,
        STATUS_DLL_INIT_FAILED             = 0xC0000142,
        STATUS_DLL_INIT_FAILED_LOGOFF      = 0xC000026B,

        CONTROL_C_EXIT                     = STATUS_CONTROL_C_EXIT,

        EXCEPTION_ACCESS_VIOLATION         = STATUS_ACCESS_VIOLATION,
        EXCEPTION_DATATYPE_MISALIGNMENT    = STATUS_DATATYPE_MISALIGNMENT,
        EXCEPTION_BREAKPOINT               = STATUS_BREAKPOINT,
        EXCEPTION_SINGLE_STEP              = STATUS_SINGLE_STEP,
        EXCEPTION_ARRAY_BOUNDS_EXCEEDED    = STATUS_ARRAY_BOUNDS_EXCEEDED,
        EXCEPTION_FLT_DENORMAL_OPERAND     = STATUS_FLOAT_DENORMAL_OPERAND,
        EXCEPTION_FLT_DIVIDE_BY_ZERO       = STATUS_FLOAT_DIVIDE_BY_ZERO,
        EXCEPTION_FLT_INEXACT_RESULT       = STATUS_FLOAT_INEXACT_RESULT,
        EXCEPTION_FLT_INVALID_OPERATION    = STATUS_FLOAT_INVALID_OPERATION,
        EXCEPTION_FLT_OVERFLOW             = STATUS_FLOAT_OVERFLOW,
        EXCEPTION_FLT_STACK_CHECK          = STATUS_FLOAT_STACK_CHECK,
        EXCEPTION_FLT_UNDERFLOW            = STATUS_FLOAT_UNDERFLOW,
        EXCEPTION_INT_DIVIDE_BY_ZERO       = STATUS_INTEGER_DIVIDE_BY_ZERO,
        EXCEPTION_INT_OVERFLOW             = STATUS_INTEGER_OVERFLOW,
        EXCEPTION_PRIV_INSTRUCTION         = STATUS_PRIVILEGED_INSTRUCTION,
        EXCEPTION_IN_PAGE_ERROR            = STATUS_IN_PAGE_ERROR,
        EXCEPTION_ILLEGAL_INSTRUCTION      = STATUS_ILLEGAL_INSTRUCTION,
        EXCEPTION_NONCONTINUABLE_EXCEPTION = STATUS_NONCONTINUABLE_EXCEPTION,
        EXCEPTION_STACK_OVERFLOW           = STATUS_STACK_OVERFLOW,
        EXCEPTION_INVALID_DISPOSITION      = STATUS_INVALID_DISPOSITION,
        EXCEPTION_GUARD_PAGE               = STATUS_GUARD_PAGE_VIOLATION,
        EXCEPTION_INVALID_HANDLE           = STATUS_INVALID_HANDLE
}

struct CREATE_THREAD_DEBUG_INFO
{
    HANDLE                 hThread;
    LPVOID                 lpThreadLocalBase;
    LPTHREAD_START_ROUTINE lpStartAddress;
}
alias CREATE_THREAD_DEBUG_INFO* LPCREATE_THREAD_DEBUG_INFO;

struct CREATE_PROCESS_DEBUG_INFO
{
    HANDLE                 hFile;
    HANDLE                 hProcess;
    HANDLE                 hThread;
    LPVOID                 lpBaseOfImage;
    DWORD                  dwDebugInfoFileOffset;
    DWORD                  nDebugInfoSize;
    LPVOID                 lpThreadLocalBase;
    LPTHREAD_START_ROUTINE lpStartAddress;
    LPVOID                 lpImageName;
    WORD                   fUnicode;
}
alias CREATE_PROCESS_DEBUG_INFO* LPCREATE_PROCESS_DEBUG_INFO;

struct EXIT_THREAD_DEBUG_INFO
{
    DWORD dwExitCode;
}
alias EXIT_THREAD_DEBUG_INFO* LPEXIT_THREAD_DEBUG_INFO;

struct EXIT_PROCESS_DEBUG_INFO
{
    DWORD dwExitCode;
}
alias EXIT_PROCESS_DEBUG_INFO* LPEXIT_PROCESS_DEBUG_INFO;

struct LOAD_DLL_DEBUG_INFO
{
    HANDLE hFile;
    LPVOID lpBaseOfDll;
    DWORD  dwDebugInfoFileOffset;
    DWORD  nDebugInfoSize;
    LPVOID lpImageName;
    WORD   fUnicode;
}
alias LOAD_DLL_DEBUG_INFO* LPLOAD_DLL_DEBUG_INFO;

struct UNLOAD_DLL_DEBUG_INFO
{
    LPVOID lpBaseOfDll;
}
alias UNLOAD_DLL_DEBUG_INFO* LPUNLOAD_DLL_DEBUG_INFO;

struct OUTPUT_DEBUG_STRING_INFO
{
    LPSTR lpDebugStringData;
    WORD  fUnicode;
    WORD  nDebugStringLength;
}
alias OUTPUT_DEBUG_STRING_INFO* LPOUTPUT_DEBUG_STRING_INFO;

struct RIP_INFO
{
    DWORD dwError;
    DWORD dwType;
}
alias RIP_INFO* LPRIP_INFO;

extern(Windows) alias DWORD function(LPVOID lpThreadParameter) LPTHREAD_START_ROUTINE;
