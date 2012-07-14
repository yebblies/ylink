
immutable ubyte[] DosHeader = cast(immutable ubyte[])
    x"4D 5A 60 00 01 00 00 00 04 00 10 00 FF FF 00 00
      FE 00 00 00 12 00 00 00 40 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
      00 00 00 00 00 00 00 00 00 00 00 00 60 00 00 00
      52 65 71 75 69 72 65 73 20 57 69 6E 33 32 20 20
      20 24 16 1F 33 D2 B4 09 CD 21 B8 01 4C CD 21 00";
static assert(DosHeader.length == 0x60);

immutable ubyte[] PE_Signature = ['P', 'E', 0, 0];

struct CoffHeader
{
align(1):
    ushort Machine;
    ushort NumberOfSections;
    uint TimeDateStamp;
    uint PointerToSymbolTable;
    uint NumberOfSymbols;
    ushort SizeOfOptionalHeader;
    ushort Characteristics;
}
static assert(CoffHeader.sizeof == 20);

enum ushort IMAGE_FILE_MACHINE_I386 = 0x14C;

enum ushort IMAGE_FILE_RELOCS_STRIPPED         = 0x0001;
enum ushort IMAGE_FILE_EXECUTABLE_IMAGE        = 0x0002;
enum ushort IMAGE_FILE_LINE_NUMS_STRIPPED      = 0x0004;
enum ushort IMAGE_FILE_LOCAL_SYMS_STRIPPED     = 0x0008;
enum ushort IMAGE_FILE_AGGRESSIVE_WS_TRIM      = 0x0010;
enum ushort IMAGE_FILE_LARGE_ADDRESS_AWARE     = 0x0020;
enum ushort IMAGE_FILE_BYTES_REVERSED_LO       = 0x0080;
enum ushort IMAGE_FILE_32BIT_MACHINE           = 0x0100;
enum ushort IMAGE_FILE_DEBUG_STRIPPED          = 0x0200;
enum ushort IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP = 0x0400;
enum ushort IMAGE_FILE_NET_RUN_FROM_SWAP       = 0x0800;
enum ushort IMAGE_FILE_SYSTEM                  = 0x1000;
enum ushort IMAGE_FILE_DLL                     = 0x2000;
enum ushort IMAGE_FILE_UP_SYSTEM_ONLY          = 0x4000;
enum ushort IMAGE_FILE_BYTES_REVERSED_HI       = 0x8000;

struct OptionalHeader
{
align(1):
    // Common
    ushort Magic;
    ubyte MajorLinkerVersion;
    ubyte MinorLinkerVersion;
    uint SizeOfCode;
    uint SizeOfInitializedData;
    uint SizeOfUninitializedData;
    uint AddressOfEntryPoint;
    uint BaseOfCode;
    uint BaseOfData; // PE only
    // Windows Only
    uint ImageBase;
    uint SectionAlignment;
    uint FileAlignment;
    ushort MajorOperatingSystemVersion;
    ushort MinorOperatingSystemVersion;
    ushort MajorImageVersion;
    ushort MinorImageVersion;
    ushort MajorSubsystemVersion;
    ushort MinorSubsystemVersion;
    uint Win32VersionValue;
    uint SizeOfImage;
    uint SizeOfHeaders;
    uint CheckSum;
    ushort Subsystem;
    ushort DllCharacteristics;
    uint SizeOfStackReserve;
    uint SizeOfStackCommit;
    uint SizeOfHeapReserve;
    uint SizeOfHeapCommit;
    uint LoaderFlags;
    uint NumberOfRvaAndSizes;
}
static assert(OptionalHeader.sizeof == 96);

enum ushort PE_MAGIC = 0x010B;

enum ushort IMAGE_SUBSYSTEM_UNKNOWN     = 0x0000;
enum ushort IMAGE_SUBSYSTEM_WINDOWS_GUI = 0x0002;
enum ushort IMAGE_SUBSYSTEM_WINDOWS_CUI = 0x0003;

enum ushort IMAGE_DLL_CHARACTERISTICS_DYNAMIC_BASE          = 0x0040;
enum ushort IMAGE_DLL_CHARACTERISTICS_FORCE_INTEGRITY       = 0x0080;
enum ushort IMAGE_DLL_CHARACTERISTICS_NX_COMPAT             = 0x0100;
enum ushort IMAGE_DLL_CHARACTERISTICS_NO_ISOLATION          = 0x0200;
enum ushort IMAGE_DLL_CHARACTERISTICS_NO_SEH                = 0x0400;
enum ushort IMAGE_DLL_CHARACTERISTICS_NO_BIND               = 0x0800;
enum ushort IMAGE_DLL_CHARACTERISTICS_WDM_DRIVER            = 0x2000;
enum ushort IMAGE_DLL_CHARACTERISTICS_TERMINAL_SERVER_AWARE = 0x8000;

struct IMAGE_DATA_DIRECTORY
{
align(1):
    uint VirtualAddress;
    uint Size;
}
static assert(IMAGE_DATA_DIRECTORY.sizeof == 8);

struct DataDirectories
{
    IMAGE_DATA_DIRECTORY ExportTable;
    IMAGE_DATA_DIRECTORY ImportTable;
    IMAGE_DATA_DIRECTORY ResourceTable;
    IMAGE_DATA_DIRECTORY ExceptionTable;
    IMAGE_DATA_DIRECTORY CertificateTable;
    IMAGE_DATA_DIRECTORY BaseRelocationTable;
    IMAGE_DATA_DIRECTORY Debug;
    IMAGE_DATA_DIRECTORY Architecture;
    IMAGE_DATA_DIRECTORY GlobalPtr;
    IMAGE_DATA_DIRECTORY TLSTable;
    IMAGE_DATA_DIRECTORY LoadConfigTable;
    IMAGE_DATA_DIRECTORY BoundImportTable;
    IMAGE_DATA_DIRECTORY ImportAddressTable;
}

struct SectionHeader
{
align(1):
    char[8] name;
    uint VirtualSize;
    uint VirtualAddress;
    uint SizeOfRawData;
    uint PointerToRawData;
    uint PointerToRelocations;
    uint PointerToLinenumbers;
    ushort NumberOfRelocations;
    ushort NumberOfLinenumbers;
    uint Characteristics;
}

enum : uint
{
    IMAGE_SCN_TYPE_NO_PAD = 0x00000008,
    IMAGE_SCN_CNT_CODE = 0x00000020,
    IMAGE_SCN_CNT_INITIALIZED_DATA = 0x00000040,
    IMAGE_SCN_CNT_UNINITIALIZED_DATA = 0x00000080,
    IMAGE_SCN_LNK_OTHER = 0x00000100,
    IMAGE_SCN_LNK_INFO = 0x00000200,
    IMAGE_SCN_LNK_REMOVE = 0x00000800,
    IMAGE_SCN_LNK_COMDAT = 0x00001000,
    IMAGE_SCN_GPREL = 0x00008000,
    IMAGE_SCN_MEM_PURGEABLE = 0x00020000,
    IMAGE_SCN_MEM_LOCKED = 0x00040000,
    IMAGE_SCN_MEM_PRELOAD = 0x00080000,
    IMAGE_SCN_ALIGN_1BYTES = 0x00100000,
    IMAGE_SCN_ALIGN_2BYTES = 0x00200000,
    IMAGE_SCN_ALIGN_4BYTES = 0x00300000,
    IMAGE_SCN_ALIGN_8BYTES = 0x00400000,
    IMAGE_SCN_ALIGN_16BYTES = 0x00500000,
    IMAGE_SCN_ALIGN_32BYTES = 0x00600000,
    IMAGE_SCN_ALIGN_64BYTES = 0x00700000,
    IMAGE_SCN_ALIGN_128BYTES = 0x00800000,
    IMAGE_SCN_ALIGN_256BYTES = 0x00900000,
    IMAGE_SCN_ALIGN_512BYTES = 0x00A00000,
    IMAGE_SCN_ALIGN_1024BYTES = 0x00B00000,
    IMAGE_SCN_ALIGN_2048BYTES = 0x00C00000,
    IMAGE_SCN_ALIGN_4096BYTES = 0x00D00000,
    IMAGE_SCN_ALIGN_8192BYTES = 0x00E00000,
    IMAGE_SCN_LNK_NRELOC_OVFL = 0x01000000,
    IMAGE_SCN_MEM_DISCARDABLE = 0x02000000,
    IMAGE_SCN_MEM_NOT_CACHED = 0x04000000,
    IMAGE_SCN_MEM_NOT_PAGED = 0x08000000,
    IMAGE_SCN_MEM_SHARED = 0x10000000,
    IMAGE_SCN_MEM_EXECUTE = 0x20000000,
    IMAGE_SCN_MEM_READ = 0x40000000,
    IMAGE_SCN_MEM_WRITE = 0x80000000,
}

struct CoffRelocation
{
align(1):
    uint VirtualAddress;
    uint SymbolTableAddress;
    ushort Type;
}

enum : ushort
{
    IMAGE_REL_I386_ABSOLUTE = 0x0000,
    IMAGE_REL_I386_DIR16 = 0x0001,
    IMAGE_REL_I386_REL16 = 0x0002,
    IMAGE_REL_I386_DIR32 = 0x0006,
    IMAGE_REL_I386_DIR32NB = 0x0007,
    IMAGE_REL_I386_SEG12 = 0x0009,
    IMAGE_REL_I386_SECTION = 0x000A,
    IMAGE_REL_I386_SECREL = 0x000B,
    IMAGE_REL_I386_TOKEN = 0x000C,
    IMAGE_REL_I386_SECREL7 = 0x000D,
    IMAGE_REL_I386_REL32 = 0x0014,
    IMAGE_REL_I386_ = 0x000,
    IMAGE_REL_I386_ = 0x000,
}
