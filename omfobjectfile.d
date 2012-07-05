
import std.exception;
import std.conv;
import std.path;
import std.stdio;

import datafile;
import omfdef;
import objectfile;
import segment;
import segmenttable;
import symbol;
import symboltable;
import workqueue;

public:

class OmfObjectFile : ObjectFile
{
private:
    DataFile f;
public:
    this(DataFile f)
    {
        super(f.filename);
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
    override void loadSymbols(SymbolTable symtab, SegmentTable segtab, WorkQueue!string queue, WorkQueue!ObjectFile objects)
    {
        immutable(ubyte)[][] sourcefiles;
        immutable(ubyte)[][] names;
        Segment[] segments;
        OmfGroup[] groups;

        objects.append(this);
        f.seek(0);
        enforce(f.peekByte() == 0x80, "First record must be THEADR");
        auto modend = false;
        while (!f.empty() && !modend)
        {
            auto r = loadRecord();
            switch(r.type)
            {
            case OmfRecordType.THEADR:
                auto len = r.data[0];
                enforce(len == r.data.length - 1, "Corrupt THEADR record");
                sourcefiles ~= r.data[1..$];
                //writeln(cast(string)r.data[1..$]);
                break;
            case OmfRecordType.LLNAMES:
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
                    queue.append(defaultExtension(cast(string)r.data[2..$], "lib"));
                    break;
                case 0xA1:
                    enforce(r.data.length == 5 &&
                            r.data[2] == 0x01 &&
                            r.data[3] == 'C' &&
                            r.data[4] == 'V',
                            "Only codeview debugging information is supported");
                    break;
                case 0xA2:
                    modend = true;
                    break;
                default:
                    enforce(false, "COMENT type " ~ to!string(cclass, 16) ~ " not supported");
                }
                break;
            case OmfRecordType.SEGDEF16:
            case OmfRecordType.SEGDEF32:
                auto data = r.data;
                enforce(data.length >= 5 || data.length <= 14, "Corrupt SEGDEF record");
                auto A = data[0] >> 5;
                auto C = (data[0] >> 2) & 7;
                auto B = (data[0] & 2) != 0;
                auto P = (data[0] & 1) != 0;

                SegmentAlign segalign;
                switch(A)
                {
                case 0: //alignment = SegmentAlignment.absolute;   break;
                    enforce(false, "Absolute segments are not supported");
                    break;
                case 1: segalign = SegmentAlign.align_1;    break;
                case 2: segalign = SegmentAlign.align_2;    break;
                case 3: segalign = SegmentAlign.align_16;   break;
                case 4: segalign = SegmentAlign.align_page; break;
                case 5: segalign = SegmentAlign.align_4;    break;
                default:
                    enforce(false, "Invalid alignment value");
                    break;
                }
                enforce(C == 2 || C == 5, "Only public segments are supported: " ~ to!string(C));
                if (C == 5) segalign = SegmentAlign.align_1;
                enforce(!B, "Big segments are not supported");
                enforce(P, "Use16 segments are not supported");
                data = data[1..$];
                uint length;
                if (r.type == OmfRecordType.SEGDEF16)
                {
                    enforce(data.length >= 2, "Corrupt SEGDEF record");
                    length = getWordLE(data);
                } else {
                    enforce(data.length >= 2, "Corrupt SEGDEF record");
                    length = getDwordLE(data);
                }
                auto name = getIndex(data);
                enforce(name <= names.length, "Invalid segment name index");
                auto cname = getIndex(data);
                enforce(cname <= names.length, "Invalid class name index");

                SegmentClass segclass;
                switch(cast(string)names[cname-1])
                {
                case "CODE":   segclass = SegmentClass.Code;   break;
                case "DATA":   segclass = SegmentClass.Data;   break;
                case "CONST":  segclass = SegmentClass.Const;  break;
                case "BSS":    segclass = SegmentClass.BSS;    break;
                case "tls":    segclass = SegmentClass.TLS;    break;
                case "ENDBSS": segclass = SegmentClass.ENDBSS; break;
                case "STACK":  segclass = SegmentClass.STACK;  break;
                default:
                    enforce(false, "Unknown segment class: " ~ cast(string)names[cname-1]);
                    break;
                }

                auto overlayName = getIndex(data); // Discard
                enforce(overlayName <= names.length, "Invalid overlay name index");
                enforce(data.length == 0, "Corrupt SEGDEF record");
                auto seg = new Segment(names[name-1], segclass, segalign, length);
                segments ~= seg;
                segtab.add(seg);
                //writeln("SEGDEF (", segments.length, ") name:", cast(string)names[name-1], " class:", cast(string)names[cname-1], " length:", length);
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
                //writeln("GRPDEF name:", cast(string)names[group.name-1], " components:", group.segs);
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
                    auto baseFrame = getWordLE(data);
                while (data.length)
                {
                    auto group = baseGroup;
                    auto seg = baseSeg;
                    auto length = getByte(data);
                    auto name = getBytes(data, length);
                    auto offset = off16 ? getWordLE(data) : getDwordLE(data);
                    auto type = getIndex(data);
                    symtab.define(new Symbol(this, seg ? segments[seg-1] : null, name, offset));
                    writeln("PUBDEF name:", cast(string)name, " ", seg ? cast(string)segments[seg-1].name : "__abs__", "+", offset);
                }
                enforce(data.length == 0, "Corrupt PUBDEF record");
                break;
            case OmfRecordType.COMDAT16:
            case OmfRecordType.COMDAT32:
                auto off16 = (r.type == OmfRecordType.PUBDEF16);
                auto data = r.data;
                auto flags = getByte(data);
                enforce(flags < 8, "COMDAT flag not supported: " ~ to!string(flags));
                auto attributes = getByte(data);
                Comdat comdat;
                switch(attributes & 0xF0)
                {
                case 0x00: comdat = Comdat.Unique; break;
                case 0x10: comdat = Comdat.Any;    break;
                default:
                    enforce(false, "COMDAT attribute not supported");
                    break;
                }
                auto alignment = getByte(data);
                auto offset = off16 ? getWordLE(data) : getDwordLE(data);
                auto type = getIndex(data);
                ushort baseGroup;
                ushort baseSeg;
                if ((attributes & 0x0F) == 0x00)
                {
                    baseGroup = getIndex(data);
                    enforce(baseGroup <= groups.length, "Invalid base group index");
                    baseSeg = getIndex(data);
                    enforce(baseSeg <= segments.length, "Invalid base segment index");
                    if (baseSeg == 0)
                        auto baseFrame = getWordLE(data);
                }
                auto name = getIndex(data);
                auto seg = segments[baseSeg-1];
                SegmentAlign segalign;
                switch(alignment)
                {
                case 0: segalign = seg.segalign;            break;
                case 1: segalign = SegmentAlign.align_1;    break;
                case 2: segalign = SegmentAlign.align_2;    break;
                case 3: segalign = SegmentAlign.align_16;   break;
                case 4: segalign = SegmentAlign.align_page; break;
                case 5: segalign = SegmentAlign.align_4;    break;
                default:
                    enforce(false, "Invalid alignment value");
                    break;
                }
                auto length = data.length;
                auto xseg = new Segment(seg.name ~ '$' ~ names[name-1], seg.segclass, segalign, length);
                segtab.add(xseg);
                //writeln(flags, ' ', attributes, ' ', comdat);
                //writeln("COMDAT name:", cast(string)names[name-1], " ", cast(string)segments[baseSeg-1].name);
                if (!(flags & 1))
                    symtab.define(new Symbol(this, xseg, names[name-1], offset, comdat));
                break;
            case OmfRecordType.EXTDEF:
                auto data = r.data;
                while (data.length)
                {
                    auto length = getByte(data);
                    auto name = getBytes(data, length);
                    auto type = getIndex(data);
                    symtab.reference(new Symbol(null, null, name, 0));
                    //writeln("EXTDEF name:", cast(string)name);
                }
                enforce(data.length == 0, "Corrupt EXTDEF record");
                break;
            case OmfRecordType.CEXTDEF:
                auto data = r.data;
                while (data.length)
                {
                    auto name = getIndex(data);
                    enforce(name <= names.length, "Invalid symbol name index");
                    auto type = getIndex(data);
                    symtab.reference(new Symbol(null, null, names[name-1], 0));
                    //writeln("CEXTDEF name:", cast(string)names[name-1]);
                }
                enforce(data.length == 0, "Corrupt CEXTDEF record");
                break;
            case OmfRecordType.COMDEF:
                auto data = r.data;
                while (data.length)
                {
                    auto name = getString(data);
                    auto type = getIndex(data);
                    auto dt = getByte(data);
                    enforce(dt == 0x61 || dt == 0x62);
                    auto length = getComLength(data);
                    if (dt == 0x61)
                        length *= getComLength(data);
                }
                enforce(data.length == 0, "Corrupt COMDEF record");
                break;
            case OmfRecordType.ALIAS:
            case OmfRecordType.LPUBDEF:
            case OmfRecordType.LCOMDEF:
            case OmfRecordType.LEXTDEF:
                enforce(false, "Record type " ~ to!string(r.type) ~ " not implemented");
                break;
            case OmfRecordType.LEDATA16:
            case OmfRecordType.LEDATA32:
            case OmfRecordType.LIDATA16:
            case OmfRecordType.LIDATA32:
            case OmfRecordType.FIXUPP16:
            case OmfRecordType.FIXUPP32:
                // Data definitions are skipped in the first pass
                break;
            case OmfRecordType.MODEND16:
            case OmfRecordType.MODEND32:
                //enforce(f.empty(), "MODEND is not at the end of object file");
                auto data = r.data;
                auto type = getByte(data);
                auto isMain = (type & 0x80) != 0;
                auto hasStart = (type & 0x40) != 0;
                auto relStart = (type & 0x01) != 0;
                enforce(!hasStart || relStart, "Relocatable start address flag must be set");
                enforce(!hasStart, "FIXME start address");
                enforce(data.length == 0, "Corrupt MODEND record");
                modend = true;
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
