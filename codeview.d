
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
    S_GPROC32    = 0x0205,
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
    LF_MLIST      = 0x0207,
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

struct CV_SEGDESC
{
align(1):
    ushort flags;
    ushort ovl;
    ushort group;
    ushort frame;
    ushort iSegName;
    ushort iClassName;
    uint offset;
    uint cbseg;
}

enum
{
    // Special Types
    T_NOTYPE = 0x0000, //Uncharacterized type (no type)
    T_ABS = 0x0001, //Absolute symbol
    T_SEGMENT = 0x0002, //Segment type
    T_VOID = 0x0003, //Void
    T_PVOID = 0x0103, //Near pointer to void
    T_PFVOID = 0x0203, //Far pointer to void
    T_PHVOID = 0x0303, //Huge pointer to void
    T_32PVOID = 0x0403, //32-bit near pointer to void
    T_32PFVOID = 0x0503, //32-bit far pointer to void
    T_CURRENCY = 0x0004, //Basic 8-byte currency value
    T_NBASICSTR = 0x0005, //Near Basic string
    T_FBASICSTR = 0x0006, //Far Basic string
    T_NOTTRANS = 0x0007, //Untranslated type record from Microsoft symbol format
    T_BIT = 0x0060, //Bit
    T_PASCHAR = 0x0061, //Pascal CHAR

    // Character Types
    T_CHAR = 0x0010, //8-bit signed
    T_UCHAR = 0x0020, //8-bit unsigned
    T_PCHAR = 0x0110, //Near pointer to 8-bit signed
    T_PUCHAR = 0x0120, //Near pointer to 8-bit unsigned
    T_PFCHAR = 0x0210, //Far pointer to 8-bit signed
    T_PFUCHAR = 0x0220, //Far pointer to 8-bit unsigned
    T_PHCHAR = 0x0310, //Huge pointer to 8-bit signed
    T_PHUCHAR = 0x0320, //Huge pointer to 8-bit unsigned
    T_32PCHAR = 0x0410, //16:32 near pointer to 8-bit signed
    T_32PUCHAR = 0x0420, //16:32 near pointer to 8-bit unsigned
    T_32PFCHAR = 0x0510, //16:32 far pointer to 8-bit signed
    T_32PFUCHAR = 0x0520, //16:32 far pointer to 8-bit unsigned

    // Real Character Types
    T_RCHAR = 0x0070, //Real char
    T_PRCHAR = 0x0170, //Near pointer to a real char
    T_PFRCHAR = 0x0270, //Far pointer to a real char
    T_PHRCHAR = 0x0370, //Huge pointer to a real char
    T_32PRCHAR = 0x0470, //16:32 near pointer to a real char
    T_32PFRCHAR = 0x0570, //16:32 far pointer to a real char

    // Wide Character Types
    T_WCHAR = 0x0071, //Wide char
    T_PWCHAR = 0x0171, //Near pointer to a wide char
    T_PFWCHAR = 0x0271, //Far pointer to a wide char
    T_PHWCHAR = 0x0371, //Huge pointer to a wide char
    T_32PWCHAR = 0x0471, //16:32 near pointer to a wide char
    T_32PFWCHAR = 0x0571, //16:32 far pointer to a wide char

    // Real 16-bit Integer Types
    T_INT2 = 0x0072, //Real 16-bit signed int
    T_UINT2 = 0x0073, //Real 16-bit unsigned int
    T_PINT2 = 0x0172, //Near pointer to 16-bit signed int
    T_PUINT2 = 0x0173, //Near pointer to 16-bit unsigned int
    T_PFINT2 = 0x0272, //Far pointer to 16-bit signed int
    T_PFUINT2 = 0x0273, //Far pointer to 16-bit unsigned int
    T_PHINT2 = 0x0372, //Huge pointer to 16-bit signed int
    T_PHUINT2 = 0x0373, //Huge pointer to 16-bit unsigned int
    T_32PINT2 = 0x0472, //16:32 near pointer to 16-bit signed int
    T_32PUINT2 = 0x0473, //16:32 near pointer to 16-bit unsigned int
    T_32PFINT2 = 0x0572, //16:32 far pointer to 16-bit signed int
    T_32PFUINT2 = 0x0573, //16:32 far pointer to 16-bit unsigned int

    // 16-bit Short Types
    T_SHORT = 0x0011, //16-bit signed
    T_USHORT = 0x0021, //16-bit unsigned
    T_PSHORT = 0x0111, //Near pointer to 16-bit signed
    T_PUSHORT = 0x0121, //Near pointer to 16-bit unsigned
    T_PFSHORT = 0x0211, //Far pointer to 16-bit signed
    T_PFUSHORT = 0x0221, //Far pointer to 16-bit unsigned
    T_PHSHORT = 0x0311, //Huge pointer to 16-bit signed
    T_PHUSHORT = 0x0321, //Huge pointer to 16-bit unsigned
    T_32PSHORT = 0x0411, //16:32 near pointer to 16-bit signed
    T_32PUSHORT = 0x0421, //16:32 near pointer to 16-bit unsigned
    T_32PFSHORT = 0x0511, //16:32 far pointer to 16-bit signed
    T_32PFUSHORT = 0x0521, //16:32 far pointer to 16-bit unsigned

    // Real 32-bit Integer Types
    T_INT4 = 0x0074, //Real 32-bit signed int
    T_UINT4 = 0x0075, //Real 32-bit unsigned int
    T_PINT4 = 0x0174, //Near pointer to 32-bit signed int
    T_PUINT4 = 0x0175, //Near pointer to 32-bit unsigned int
    T_PFINT4 = 0x0274, //Far pointer to 32-bit signed int
    T_PFUINT4 = 0x0275, //Far pointer to 32-bit unsigned int
    T_PHINT4 = 0x0374, //Huge pointer to 32-bit signed int
    T_PHUINT4 = 0x0375, //Huge pointer to 32-bit unsigned int
    T_32PINT4 = 0x0474, //16:32 near pointer to 32-bit signed int
    T_32PUINT4 = 0x0475, //16:32 near pointer to 32-bit unsigned int
    T_32PFINT4 = 0x0574, //16:32 far pointer to 32-bit signed int
    T_32PFUINT4 = 0x0575, //16:32 far pointer to 32-bit unsigned int

    // 32-bit Long Types
    T_LONG = 0x0012, //32-bit signed
    T_ULONG = 0x0022, //32-bit unsigned
    T_PLONG = 0x0112, //Near pointer to 32-bit signed
    T_PULONG = 0x0122, //Near pointer to 32-bit unsigned
    T_PFLONG = 0x0212, //Far pointer to 32-bit signed
    T_PFULONG = 0x0222, //Far pointer to 32-bit unsigned
    T_PHLONG = 0x0312, //Huge pointer to 32-bit signed
    T_PHULONG = 0x0322, //Huge pointer to 32-bit unsigned
    T_32PLONG = 0x0412, //16:32 near pointer to 32-bit signed
    T_32PULONG = 0x0422, //16:32 near pointer to 32-bit unsigned
    T_32PFLONG = 0x0512, //16:32 far pointer to 32-bit signed
    T_32PFULONG = 0x0522, //16:32 far pointer to 32-bit unsigned

    // Real 64-bit int Types
    T_INT8 = 0x0076, //64-bit signed int
    T_UINT8 = 0x0077, //64-bit unsigned int
    T_PINT8 = 0x0176, //Near pointer to 64-bit signed int
    T_PUINT8 = 0x0177, //Near pointer to 64-bit unsigned int
    T_PFINT8 = 0x0276, //Far pointer to 64-bit signed int
    T_PFUINT8 = 0x0277, //Far pointer to 64-bit unsigned int
    T_PHINT8 = 0x0376, //Huge pointer to 64-bit signed int
    T_PHUINT8 = 0x0377, //Huge pointer to 64-bit unsigned int
    T_32PINT8 = 0x0476, //16:32 near pointer to 64-bit signed int
    T_32PUINT8 = 0x0477, //16:32 near pointer to 64-bit unsigned int
    T_32PFINT8 = 0x0576, //16:32 far pointer to 64-bit signed int
    T_32PFUINT8 = 0x0577, //16:32 far pointer to 64-bit unsigned int

    // 64-bit Integral Types
    T_QUAD = 0x0013, //64-bit signed
    T_UQUAD = 0x0023, //64-bit unsigned
    T_PQUAD = 0x0113, //Near pointer to 64-bit signed
    T_PUQUAD = 0x0123, //Near pointer to 64-bit unsigned
    T_PFQUAD = 0x0213, //Far pointer to 64-bit signed
    T_PFUQUAD = 0x0223, //Far pointer to 64-bit unsigned
    T_PHQUAD = 0x0313, //Huge pointer to 64-bit signed
    T_PHUQUAD = 0x0323, //Huge pointer to 64-bit unsigned
    T_32PQUAD = 0x0413, //16:32 near pointer to 64-bit signed
    T_32PUQUAD = 0x0423, //16:32 near pointer to 64-bit unsigned
    T_32PFQUAD = 0x0513, //16:32 far pointer to 64-bit signed
    T_32PFUQUAD = 0x0523, //16:32 far pointer to 64-bit unsigned

    // 32-bit Real Types
    T_REAL32 = 0x0040, //32-bit real
    T_PREAL32 = 0x0140, //Near pointer to 32-bit real
    T_PFREAL32 = 0x0240, //Far pointer to 32-bit real
    T_PHREAL32 = 0x0340, //Huge pointer to 32-bit real
    T_32PREAL32 = 0x0440, //16:32 near pointer to 32-bit real
    T_32PFREAL32 = 0x0540, //16:32 far pointer to 32-bit real

    // 48-bit Real Types
    T_REAL48 = 0x0044, //48-bit real
    T_PREAL48 = 0x0144, //Near pointer to 48-bit real
    T_PFREAL48 = 0x0244, //Far pointer to 48-bit real
    T_PHREAL48 = 0x0344, //Huge pointer to 48-bit real
    T_32PREAL48 = 0x0444, //16:32 near pointer to 48-bit real
    T_32PFREAL48 = 0x0544, //16:32 far pointer to 48-bit real

    // 64-bit Real Types
    T_REAL64 = 0x0041, //64-bit real
    T_PREAL64 = 0x0141, //Near pointer to 64-bit real
    T_PFREAL64 = 0x0241, //Far pointer to 64-bit real
    T_PHREAL64 = 0x0341, //Huge pointer to 64-bit real
    T_32PREAL64 = 0x0441, //16:32 near pointer to 64-bit real
    T_32PFREAL64 = 0x0541, //16:32 far pointer to 64-bit real

    // 80-bit Real Types
    T_REAL80 = 0x0042, //80-bit real
    T_PREAL80 = 0x0142, //Near pointer to 80-bit real
    T_PFREAL80 = 0x0242, //Far pointer to 80-bit real
    T_PHREAL80 = 0x0342, //Huge pointer to 80-bit real
    T_32PREAL80 = 0x0442, //16:32 near pointer to 80-bit real
    T_32PFREAL80 = 0x0542, //16:32 far pointer to 80-bit real

    // 128-bit Real Types
    T_REAL128 = 0x0043, //128-bit real
    T_PREAL128 = 0x0143, //Near pointer to 128-bit real
    T_PFREAL128 = 0x0243, //Far pointer to 128-bit real
    T_PHREAL128 = 0x0343, //Huge pointer to 128-bit real
    T_32PREAL128 = 0x0443, //16:32 near pointer to 128-bit real
    T_32PFREAL128 = 0x0543, //16:32 far pointer to 128-bit real

    // 32-bit Complex Types
    T_CPLX32 = 0x0050, //32-bit complex
    T_PCPLX32 = 0x0150, //Near pointer to 32-bit complex
    T_PFCPLX32 = 0x0250, //Far pointer to 32-bit complex
    T_PHCPLX32 = 0x0350, //Huge pointer to 32-bit complex
    T_32PCPLX32 = 0x0450, //16:32 near pointer to 32-bit complex
    T_32PFCPLX32 = 0x0550, //16:32 far pointer to 32-bit complex

    // 64-bit Complex Types
    T_CPLX64 = 0x0051, //64-bit complex
    T_PCPLX64 = 0x0151, //Near pointer to 64-bit complex
    T_PFCPLX64 = 0x0251, //Far pointer to 64-bit complex
    T_PHCPLX64 = 0x0351, //Huge pointer to 64-bit complex
    T_32PCPLX64 = 0x0451, //16:32 near pointer to 64-bit complex
    T_32PFCPLX64 = 0x0551, //16:32 far pointer to 64-bit complex

    // 80-bit Complex Types
    T_CPLX80 = 0x0052, //80-bit complex
    T_PCPLX80 = 0x0152, //Near pointer to 80-bit complex
    T_PFCPLX80 = 0x0252, //Far pointer to 80-bit complex
    T_PHCPLX80 = 0x0352, //Huge pointer to 80-bit complex
    T_32PCPLX80 = 0x0452, //16:32 near pointer to 80-bit complex
    T_32PFCPLX80 = 0x0552, //16:32 far pointer to 80-bit complex

    // 128-bit Complex Types
    T_CPLX128 = 0x0053, //128-bit complex
    T_PCPLX128 = 0x0153, //Near pointer to 128-bit complex
    T_PFCPLX128 = 0x0253, //Far pointer to 128-bit complex
    T_PHCPLX128 = 0x0353, //Huge pointer to 128-bit real
    T_32PCPLX128 = 0x0453, //16:32 near pointer to 128-bit complex
    T_32PFCPLX128 = 0x0553, //16:32 far pointer to 128-bit complex

    // Boolean Types
    T_BOOL08 = 0x0030, //8-bit Boolean
    T_BOOL16 = 0x0031, //16-bit Boolean
    T_BOOL32 = 0x0032, //32-bit Boolean
    T_BOOL64 = 0x0033, //64-bit Boolean
    T_PBOOL08 = 0x0130, //Near pointer to 8-bit Boolean
    T_PBOOL16 = 0x0131, //Near pointer to 16-bit Boolean
    T_PBOOL32 = 0x0132, //Near pointer to 32-bit Boolean
    T_PBOOL64 = 0x0133, //Near pointer to 64-bit Boolean
    T_PFBOOL08 = 0x0230, //Far pointer to 8-bit Boolean
    T_PFBOOL16 = 0x0231, //Far pointer to 16-bit Boolean
    T_PFBOOL32 = 0x0232, //Far pointer to 32-bit Boolean
    T_PFBOOL64 = 0x0233, //Far pointer to 64-bit Boolean
    T_PHBOOL08 = 0x0330, //Huge pointer to 8-bit Boolean
    T_PHBOOL16 = 0x0331, //Huge pointer to 16-bit Boolean
    T_PHBOOL32 = 0x0332, //Huge pointer to 32-bit Boolean
    T_PHBOOL64 = 0x0333, //Huge pointer to 64-bit Boolean
    T_32PBOOL08 = 0x0430, //16:32 near pointer to 8-bit Boolean
    T_32PBOOL16 = 0x0431, //16:32 near pointer to 16-bit Boolean
    T_32PBOOL32 = 0x0432, //16:32 near pointer to 32-bit Boolean
    T_32PBOOL64 = 0x0433, //16:32 near pointer to 64-bit Boolean
    T_32PFBOOL08 = 0x0530, //16:32 far pointer to 8-bit Boolean
    T_32PFBOOL16 = 0x0531, //16:32 far pointer to 16-bit Boolean
    T_32PFBOOL32 = 0x0532, //16:32 far pointer to 32-bit Boolean
    T_32PFBOOL64 = 0x0533, //16:32 far pointer to 64-bit Boolean
}
