
enum CV41_SIG = '9' << 24 | '0' << 16 | 'B' << 8 | 'N';

struct CV_DIRHEADER
{
    ushort cbDirHeader;
    ushort cbDirEntry;
    uint cDir;
    uint lfoNextDir;
    uint flags;
}

struct CV_DIRENTRY
{
    ushort subsection;
    ushort iMod;
    uint lfo;
    uint cb;
}

enum : ushort
{
    sstModule = 0x120,
    sstTypes = 0x121,
    sstPublic = 0x122,
    sstPublicSym = 0x123,
    sstSymbols = 0x124,
    sstAlignSym = 0x125,
    sstSrcLnSeg = 0x126,
    sstSrcModule = 0x127,
    sstLibraries = 0x128,
    sstGlobalSym = 0x129,
    sstGlobalPub = 0x12A,
    sstGlobalTypes = 0x12B,
    sstMPC = 0x12C,
    sstSegMap = 0x12D,
    sstSegName = 0x12E,
    sstPreComp = 0x12F,
    sstFileIndex = 0x133,
    sstStaticSym = 0x134,
}

enum : ushort
{
    S_COMPILE    = 0x0001,
    S_REGISTER   = 0x0002,
    S_CONSTANT   = 0x0003,
    S_UDT        = 0x0004,
    S_SSEARCH    = 0x0005,
    S_END        = 0x0006,
    S_SKIP       = 0x0007,
    S_CVRESERVE  = 0x0008,
    S_OBJNAME    = 0x0009,
    S_ENDARG     = 0x000A,
    S_COBOLUDT   = 0x000B,
    S_MANYREG    = 0x000C,
    S_RETURN     = 0x000D,
    S_ENTRYTHIS  = 0x000E,

    S_BPREL16    = 0x0100,
    S_LDATA16    = 0x0101,
    S_GDATA16    = 0x0102,
    S_PUB16      = 0x0103,
    S_LPROC16    = 0x0104,
    S_GPROC16    = 0x0105,
    S_THUNK16    = 0x0106,
    S_BLOCK16    = 0x0107,
    S_WITH16     = 0x0108,
    S_LABEL16    = 0x0109,
    S_CEXMODEL16 = 0x010A,
    S_VFTPATH16  = 0x010B,
    S_REGREL16   = 0x010C,

    S_BPREL32    = 0x0200,
    S_LDATA32    = 0x0201,
    S_GDATA32    = 0x0202,
    S_PUB32      = 0x0203,
    S_LPROC32    = 0x0204,
    S_GRPOC32    = 0x0205,
    S_THUNK32    = 0x0206,
    S_BLOCK32    = 0x0207,
    S_VFTPATH32  = 0x020B,
    S_REGREL32   = 0x020C,
    S_LTHREAD32  = 0x020D,
    S_GTHREAD32  = 0x020E,

    S_LPROCMIPS  = 0x0300,
    S_GPROCMIPS  = 0x0301,

    S_PROCREF    = 0x0400,
    S_DATAREF    = 0x0401,
    S_ALIGN      = 0x0402,
}

enum : ushort
{
    LF_MODIFIER   = 0x0001,
    LF_POINTER    = 0x0002,
    LF_ARRAY      = 0x0003,
    LF_CLASS      = 0x0004,
    LF_STRUCTURE  = 0x0005,
    LF_UNION      = 0x0006,
    LF_ENUM       = 0x0007,
    LF_PROCEDURE  = 0x0008,
    LF_MFUNCTION  = 0x0009,
    LF_VTSHAPE    = 0x000A,
    LF_COBOL0     = 0x000B,
    LF_COBOL1     = 0x000C,
    LF_BARRAY     = 0x000D,
    LF_LABEL      = 0x000E,
    LF_NULL       = 0x000F,
    LF_NOTTRAN    = 0x0010,
    LF_DIMARRAY   = 0x0011,
    LF_VFTPATH    = 0x0012,
    LF_PRECOMP    = 0x0013,
    LF_ENDPRECOMP = 0x0014,
    LF_OEM        = 0x0015,

    LF_SKIP       = 0x0200,
    LF_ARGLIST    = 0x0201,
    LF_DEFARG     = 0x0202,
    LF_LIST       = 0x0203,
    LF_FIELDLIST  = 0x0204,
    LF_DERIVED    = 0x0205,
    LF_BITFIELD   = 0x0206,
    LF_METHODLIST = 0x0207,
    LF_DIMCONU    = 0x0208,
    LF_DIMCONLU   = 0x0209,
    LF_DIMVARU    = 0x020A,
    LF_DIMVARLU   = 0x020B,
    LF_REFSYM     = 0x020C,

    LF_BCLASS     = 0x0400,
    LF_VBCLASS    = 0x0401,
    LF_IVBCLASS   = 0x0402,
    LF_ENUMERATE  = 0x0403,
    LF_FRIENDFCN  = 0x0404,
    LF_INDEX      = 0x0405,
    LF_MEMBER     = 0x0406,
    LF_STMEMBER   = 0x0407,
    LF_METHOD     = 0x0408,
    LF_NESTTYPE   = 0x0409,
    LF_VFUNCTAB   = 0x040A,
    LF_FRIENDCLS  = 0x040B,
    LF_ONEMETHOD  = 0x040C,
    LF_VFUNCOFF   = 0x040D,

    LF_NUMERIC    = 0x8000,
    LF_CHAR       = 0x8000,
    LF_SHORT      = 0x8001,
    LF_USHORT     = 0x8002,
    LF_LONG       = 0x8003,
    LF_ULONG      = 0x8004,
    LF_REAL32     = 0x8005,
    LF_REAL64     = 0x8006,
    LF_REAL80     = 0x8007,
    LF_REAL128    = 0x8008,
    LF_QUADWORD   = 0x8009,
    LF_UQUADWORD  = 0x800A,
    LF_REAL48     = 0x800B,
    LF_COMPLEX32  = 0x800C,
    LF_COMPLEX64  = 0x800D,
    LF_COMPLEX80  = 0x800E,
    LF_COMPLEX128 = 0x800F,
    LF_VARSTRING  = 0x8010,

    LF_PAD0       = 0x00F0,
    LF_PAD1       = 0x00F1,
    LF_PAD2       = 0x00F2,
    LF_PAD3       = 0x00F3,
    LF_PAD4       = 0x00F4,
    LF_PAD5       = 0x00F5,
    LF_PAD6       = 0x00F6,
    LF_PAD7       = 0x00F7,
    LF_PAD8       = 0x00F8,
    LF_PAD9       = 0x00F9,
    LF_PAD10      = 0x00FA,
    LF_PAD11      = 0x00FB,
    LF_PAD12      = 0x00FC,
    LF_PAD13      = 0x00FD,
    LF_PAD14      = 0x00FE,
    LF_PAD15      = 0x00FF,
}
