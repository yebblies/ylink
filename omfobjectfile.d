
import std.exception;
import std.conv;
import std.stdio;

import datafile;
import omfdef;
import objectfile;
import segment;
import segmenttable;
import symboltable;

public:

class OmfObjectFile : ObjectFile
{
private:
    DataFile f;
public:
    this(DataFile f)
    {
        this.f = f;
    }
    override void dump()
    {
        writeln("OMF Object file: ", f.filename);
        f.seek(0);
        while (!f.empty)
        {
            auto r = loadRecord();
            r.dump();
        }
    }
    override void loadSymbols(SymbolTable symtab, SegmentTable segtab)
    {
        immutable(ubyte)[][] defaultLibrary;
        immutable(ubyte)[][] sourcefiles;
        immutable(ubyte)[][] names;
        OmfSegment[] segments;
        OmfGroup[] groups;
        OmfPublicSymbol[] publicSymbols;
        OmfExternalSymbol[] externalSymbols;
        OmfExternalComdatSymbol[] externalComdatSymbols;

        f.seek(0);
        enforce(f.peekByte() == 0x80, "First record must be THEADR");
        while (!f.empty)
        {
            auto r = loadRecord();
            switch(r.type)
            {
            case OmfRecordType.THEADR:
                auto len = r.data[0];
                enforce(len == r.data.length - 1, "Corrupt THEADR record");
                sourcefiles ~= r.data[1..$];
                break;
            case OmfRecordType.LNAMES:
                auto data = r.data;
                enforce(data.length != 0, "Empty LNAMES record");
                while (data.length != 0)
                {
                    auto len = data[0];
                    enforce(len + 1 <= data.length, "Name length too long");
                    names ~= data[1..1+len];
                    data = data[1+len..$];
                }
                break;
            case OmfRecordType.COMENT:
                enforce(r.data.length >= 2, "Corrupt COMENT record");
                auto ctype = r.data[0];
                auto cclass = r.data[1];
                switch(cclass)
                {
                case 0x9D:
                    checkMemoryModel(r.data[2..$]);
                    break;
                case 0x9F:
                    defaultLibrary ~= r.data[2..$];
                    break;
                case 0xA1:
                    enforce(r.data.length == 5 &&
                            r.data[2] == 0x01 &&
                            r.data[3] == 'C' &&
                            r.data[4] == 'V',
                            "Only codeview debugging information is supported");
                    break;
                default:
                    enforce(false, "COMENT type " ~ to!string(cclass, 16) ~ " not supported");
                }
                break;
            case OmfRecordType.SEGDEF16:
            case OmfRecordType.SEGDEF32:
                OmfSegment seg;
                auto data = r.data;
                enforce(data.length >= 5 || data.length <= 14, "Corrupt SEGDEF record");
                auto A = data[0] >> 5;
                auto C = (data[0] >> 2) & 7;
                auto B = (data[0] & 2) != 0;
                auto P = (data[0] & 1) != 0;

                switch(A)
                {
                case 0: //alignment = SegmentAlignment.absolute;   break;
                    enforce(false, "Absolute segments are not supported");
                    break;
                case 1: seg.alignment = SegmentAlignment.align_1;    break;
                case 2: seg.alignment = SegmentAlignment.align_2;    break;
                case 3: seg.alignment = SegmentAlignment.align_16;   break;
                case 4: seg.alignment = SegmentAlignment.align_page; break;
                case 5: seg.alignment = SegmentAlignment.align_4;    break;
                default:
                    enforce(false, "Invalid alignment value");
                    break;
                }
                enforce(C == 2, "Only public segments are supported");
                enforce(!B, "Big segments are not supported");
                enforce(P, "Use16 segments are not supported");
                data = data[1..$];
                if (r.type == OmfRecordType.SEGDEF16)
                {
                    enforce(data.length >= 2, "Corrupt SEGDEF record");
                    seg.length = getWordLE(data);
                } else {
                    enforce(data.length >= 2, "Corrupt SEGDEF record");
                    seg.length = getDwordLE(data);
                }
                seg.name = getIndex(data);
                enforce(seg.name <= names.length, "Invalid segment name index");
                seg.cname = getIndex(data);
                enforce(seg.cname <= names.length, "Invalid class name index");
                auto overlayName = getIndex(data); // Discard
                enforce(overlayName <= names.length, "Invalid overlay name index");
                enforce(data.length == 0, "Corrupt SEGDEF record");
                segments ~= seg;
                writeln("SEGDEF (", segments.length, ") name:", cast(string)names[seg.name-1], " class:", cast(string)names[seg.cname-1], " length:", seg.length);
                break;
            case OmfRecordType.GRPDEF:
                OmfGroup group;
                auto data = r.data;
                group.name = getIndex(data);
                enforce(group.name <= names.length, "Invalid group name index");
                while (data.length)
                {
                    auto type = getByte(data);
                    enforce(type == 0xFF, "Only type FFH group components are supported");
                    auto index = getIndex(data);
                    enforce(index <= segments.length, "Invalid group segment index");
                    group.segs ~= index;
                }
                groups ~= group;
                writeln("GRPDEF name:", cast(string)names[group.name-1], " components:", group.segs);
                enforce(data.length == 0, "Corrupt GRPDEF record");
                break;
            case OmfRecordType.PUBDEF16:
            case OmfRecordType.PUBDEF32:
                auto off16 = (r.type == OmfRecordType.PUBDEF16);
                auto data = r.data;
                auto baseGroup = getIndex(data);
                enforce(baseGroup <= groups.length, "Invalid base group index");
                auto baseSeg = getIndex(data);
                enforce(baseSeg <= segments.length, "Invalid base segment index");
                if (baseSeg == 0)
                    getWordLE(data);
                while (data.length)
                {
                    OmfPublicSymbol sym;
                    sym.group = baseGroup;
                    sym.seg = baseSeg;
                    auto length = getByte(data);
                    sym.name = getBytes(data, length);
                    sym.offset = off16 ? getWordLE(data) : getDwordLE(data);
                    sym.type = getIndex(data);
                    publicSymbols ~= sym;
                    writeln("PUBDEF name:", cast(string)sym.name, " ", cast(string)names[segments[sym.seg-1].name-1], "+", sym.offset);
                }
                enforce(data.length == 0, "Corrupt PUBDEF record");
                break;
            case OmfRecordType.EXTDEF:
                auto data = r.data;
                while (data.length)
                {
                    OmfExternalSymbol sym;
                    auto length = getByte(data);
                    sym.name = getBytes(data, length);
                    sym.type = getIndex(data);
                    externalSymbols ~= sym;
                    writeln("EXTDEF name:", cast(string)sym.name);
                }
                enforce(data.length == 0, "Corrupt EXTDEF record");
                break;
            case OmfRecordType.CEXTDEF:
                auto data = r.data;
                while (data.length)
                {
                    OmfExternalComdatSymbol sym;
                    sym.name = getIndex(data);
                    enforce(sym.name <= names.length, "Invalid symbol name index");
                    sym.type = getIndex(data);
                    externalComdatSymbols ~= sym;
                    writeln("CEXTDEF name:", cast(string)names[sym.name-1]);
                }
                enforce(data.length == 0, "Corrupt CEXTDEF record");
                break;
            case OmfRecordType.LLNAMES:
            case OmfRecordType.ALIAS:
            case OmfRecordType.LPUBDEF:
            case OmfRecordType.COMDEF:
            case OmfRecordType.LCOMDEF:
            case OmfRecordType.LEXTDEF:
                enforce(false, "Record type " ~ to!string(r.type) ~ " not implemented");
                break;
            case OmfRecordType.COMDAT16:
            case OmfRecordType.COMDAT32:
            case OmfRecordType.LEDATA16:
            case OmfRecordType.LEDATA32:
            case OmfRecordType.FIXUPP16:
            case OmfRecordType.FIXUPP32:
                // Data definitions are skipped in the first pass
                break;
            case OmfRecordType.MODEND16:
            case OmfRecordType.MODEND32:
                enforce(f.empty(), "MODEND is not at the end of object file");
                auto data = r.data;
                auto type = getByte(data);
                auto isMain = (type & 0x80) != 0;
                auto hasStart = (type & 0x40) != 0;
                auto relStart = (type & 0x01) != 0;
                enforce(!hasStart || relStart, "Relocatable start address flag must be set");
                enforce(!hasStart, "FIXME start address");
                enforce(data.length == 0, "Corrupt MODEND record");
                break;
            default:
                enforce(false, "Unsupported record type: " ~ to!string(r.type));
                break;
            }
        }
    }
private:
    OmfRecord loadRecord()
    {
        OmfRecord r;
        r.type = OmfRecord.recordType(f.readByte());
        r.data = f.readBytes(f.readWordLE())[0..$-1];
        return r;
    }
    void checkMemoryModel(in ubyte[] s)
    {
        foreach(c; s)
        {
            switch(c)
            {
            case 'A':
                enforce(false, "68000 memory model is not supported");
                break;
            case 'B':
                enforce(false, "68010 memory model is not supported");
                break;
            case 'C':
                enforce(false, "68020 memory model is not supported");
                break;
            case 'D':
                enforce(false, "68030 memory model is not supported");
                break;
            case '0':
                enforce(false, "8086 memory model is not supported");
                break;
            case '1':
                enforce(false, "80186 memory model is not supported");
                break;
            case '2':
                enforce(false, "80286 memory model is not supported");
                break;
            case '3':
                enforce(false, "80386 memory model is not supported");
                break;
            case '7':
                // 786, apparently ok
                break;
            case 'O':
                // We don't care about optimization
                break;
            case 's':
                enforce(false, "small memory model is not supported");
                break;
            case 'm':
                enforce(false, "medium memory model is not supported");
                break;
            case 'c':
                enforce(false, "compact memory model is not supported");
                break;
            case 'l':
                enforce(false, "large memory model is not supported");
                break;
            case 'h':
                enforce(false, "huge memory model is not supported");
                break;
            case 'n':
                // Windows NT memory model
                break;
            default:
                enforce(false, "Corrupt COMENT record");
            }
        }
    }
}
