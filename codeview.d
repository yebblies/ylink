
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
