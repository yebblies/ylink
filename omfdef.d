
import std.conv;
import std.exception;
import std.stdio;

import datafile;

enum OmfRecordType
{
    THEADR, // Translator Header Record
    LHEADR, // Library Module Header Record
    COMENT, // Comment Record (Including all comment class extensions)
    MODEND16, // Module End Record
    MODEND32, // Module End Record
    EXTDEF, // External Names Definition Record
    PUBDEF16, // Public Names Definition Record
    PUBDEF32, // Public Names Definition Record
    LINNUM, // Line Numbers Record
    LNAMES, // List of Names Record
    SEGDEF16, // Segment Definition Record
    SEGDEF32, // Segment Definition Record
    GRPDEF, // Group Definition Record
    FIXUPP16, // Fixup Record
    FIXUPP32, // Fixup Record
    LEDATA16, // Logical Enumerated Data Record
    LEDATA32, // Logical Enumerated Data Record
    LIDATA16, // Logical Iterated Data Record
    LIDATA32, // Logical Iterated Data Record
    COMDEF, // Communal Names Definition Record
    BAKPAT, // Backpatch Record
    LEXTDEF, // Local External Names Definition Record
    LPUBDEF, // Local Public Names Definition Record
    LCOMDEF, // Local Communal Names Definition Record
    CEXTDEF, // COMDAT External Names Definition Record
    COMDAT16, // Initialized Communal Data Record
    COMDAT32, // Initialized Communal Data Record
    LINSYM, // Symbol Line Numbers Record
    ALIAS, // Alias Definition Record
    NBKPAT, // Named Backpatch Record
    LLNAMES, // Local Logical Names Definition Record
    VERNUM, // OMF Version Number Record
    VENDEXT, // Vendor-specific OMF Extension Record
    LIBHEADR,
    LIBEND,
};

struct OmfRecord
{
    OmfRecordType type;
    immutable(ubyte)[] data;

    void dump()
    {
        writeln(type, ": ", data.length, " bytes");
    }

    static OmfRecordType recordType(ubyte b)
    {
        with (OmfRecordType)
        switch(b)
        {
        case 0x80: return THEADR;
        case 0x82: return LHEADR;
        case 0x88: return COMENT;
        case 0x8A: return MODEND16;
        case 0x8B: return MODEND32;
        case 0x8C: return EXTDEF;
        case 0x90: return PUBDEF16;
        case 0x91: return PUBDEF32;
        case 0x94:
        case 0x95: return LINNUM;
        case 0x96: return LNAMES;
        case 0x98: return SEGDEF16;
        case 0x99: return SEGDEF32;
        case 0x9A: return GRPDEF;
        case 0x9C: return FIXUPP16;
        case 0x9D: return FIXUPP32;
        case 0xA0: return LEDATA16;
        case 0xA1: return LEDATA32;
        case 0xA2: return LIDATA16;
        case 0xA3: return LIDATA32;
        case 0xB0: return COMDEF;
        case 0xB2:
        case 0xB3: return BAKPAT;
        case 0xB4: return LEXTDEF;
        case 0xB6:
        case 0xB7: return LPUBDEF;
        case 0xB8: return LCOMDEF;
        case 0xBC: return CEXTDEF;
        case 0xC2: return COMDAT16;
        case 0xC3: return COMDAT32;
        case 0xC4:
        case 0xC5: return LINSYM;
        case 0xC6: return ALIAS;
        case 0xC8:
        case 0xC9: return NBKPAT;
        case 0xCA: return LLNAMES;
        case 0xCC: return VERNUM;
        case 0xCE: return VENDEXT;
        case 0xF0: return LIBHEADR;
        case 0xF1: return LIBEND;
        default:
            enforce(false, "Invalid omf record type: " ~ to!string(b, 16));
            assert(0);
        }
    }
}

ushort getIndex(ref immutable(ubyte)[] d)
{
    ushort r;
    if (d.length == 0)
        r = ushort.max;
    else if (d.length == 1 && (d[0] & 0x80))
        r = ushort.max;
    else if (d[0] & 0x80)
    {
        r = ((d[0] & 0x7F) << 8) | d[1];
        d = d[2..$];
    }
    else
    {
        r = d[0] & 0x7F;
        d = d[1..$];
    }
    return r;
}

immutable(ubyte)[] getString(ref immutable(ubyte)[] d)
{
    ubyte n = d[0];
    auto r = d[1..n+1];
    d = d[n+1..$];
    return r;
}

uint getComLength(ref immutable(ubyte)[] d)
{
    auto l = getByte(d);
    if (l <= 128)
        return l;
    else if (l == 0x81)
        return getWordLE(d);
    else if (l == 0x84)
    {
        auto r = getWordLE(d);
        return r | (getByte(d) << 16);
    }
    else if (l == 0x88)
        return getDwordLE(d);
    assert(0);
}

struct OmfGroup
{
    ushort name;
    ushort[] segs;
}
