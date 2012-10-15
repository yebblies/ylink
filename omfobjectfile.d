
import std.algorithm;
import std.exception;
import std.conv;
import std.path;
import std.stdio;

import datafile;
import modules;
import omfdef;
import objectfile;
import section;
import sectiontable;
import segment;
import symbol;
import symboltable;
import workqueue;

public:

final class OmfObjectFile : ObjectFile
{
private:
    DataFile f;
    immutable(ubyte)[] sourcefile;
    immutable(ubyte)[][] names;
    Section[] sections;
    OmfGroup[] groups;
    immutable(ubyte)[][] externs;
    SymbolTable symtab;
public:
    this(DataFile f)
    {
        super(f.filename);
        this.f = f;
    }
    override void dump()
    {
        //writeln("OMF Object file: ", f.filename);
        f.seek(0);
        while (!f.empty)
        {
            auto r = loadRecord();
            r.dump();
        }
    }
    override void loadSymbols(SymbolTable xsymtab, SectionTable sectab, WorkQueue!string queue, WorkQueue!ObjectFile objects)
    {
        //writeln("OMF Object file: ", f.filename);

        symtab = new SymbolTable(xsymtab);
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
                sourcefile = r.data[1..$];
                //writeln("Module: ", cast(string)r.data[1..$]);
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
                auto data = r.data;
                auto ctype = getByte(data);
                auto cclass = getByte(data);
                switch(cclass)
                {
                case 0x9D:
                    checkMemoryModel(getBytes(data, 2));
                    break;
                case 0x9E:
                    // DOSSEG
                    break;
                case 0x9F:
                    queue.append(defaultExtension(cast(string)data, "lib"));
                    break;
                case 0xA0:
                    auto subtype = getByte(data);
                    switch(subtype)
                    {
                    case 0x01: // IMPDEF
                        auto isOrdinal = getByte(data);
                        auto intname = getString(data);
                        auto modname = getString(data);
                        ushort entryOrd;
                        immutable(ubyte)[] expname;
                        if (isOrdinal)
                            entryOrd = getWordLE(data);
                        else
                        {
                            expname = getString(data);
                            if (expname.length == 0)
                                expname = intname;
                        }
                        enforce(data.length == 0, "Corrupt IMPDEF record");
                        //writeln("IMPDEF int:", cast(string)intname, " mod:", cast(string)modname, " ent:", isOrdinal ? to!string(entryOrd) : cast(string)expname);
                        symtab.add(new ImportSymbol(modname, entryOrd, intname, expname));
                        break;
                    default:
                        enforce(false, "COMENT A0 subtype " ~ to!string(subtype, 16) ~ " not supported");
                        break;
                    }
                    break;
                case 0xA1:
                    enforce(data.length == 3 &&
                            getByte(data) == 0x01 &&
                            getByte(data) == 'C' &&
                            getByte(data) == 'V',
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

                SectionAlign secalign;
                switch(A)
                {
                case 0: //alignment = SectionAlignment.absolute;   break;
                    enforce(false, "Absolute sections are not supported");
                    break;
                case 1: secalign = SectionAlign.align_1;    break;
                case 2: secalign = SectionAlign.align_2;    break;
                case 3: secalign = SectionAlign.align_16;   break;
                case 4: secalign = SectionAlign.align_page; break;
                case 5: secalign = SectionAlign.align_4;    break;
                default:
                    enforce(false, "Invalid alignment value");
                    break;
                }
                switch(C)
                {
                case 5:
                    secalign = SectionAlign.align_1;
                case 2, 4, 7:
                case 0:
                    break;
                default:
                    enforce(false, "Section combination not supported: " ~ to!string(C));
                    break;
                }
                enforce(!B, "Big sections are not supported");
                enforce(P, "Use16 sections are not supported");
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
                enforce(name <= names.length, "Invalid section name index");
                auto cname = getIndex(data);
                enforce(cname <= names.length, "Invalid class name index");

                auto secclass = getSectionClass(names[cname-1]);
                auto overlayName = getIndex(data); // Discard
                enforce(overlayName <= names.length, "Invalid overlay name index");
                enforce(data.length == 0, "Corrupt SEGDEF record");
                auto sec = new Section(names[name-1], secclass, secalign, length);
                sections ~= sec;
                sectab.add(sec);
                //writeln("SEGDEF (", sections.length, ") name:", cast(string)names[name-1], " class:", cast(string)names[cname-1], " length:", length, " align:", secalign);
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
                    enforce(index <= sections.length, "Invalid group section index");
                    group.segs ~= index;
                }
                //enforce(cast(string)names[group.name-1] == "FLAT", "Only the FLAT group is supported, not " ~ cast(string)names[group.name-1]);
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
                auto baseSec = getIndex(data);
                enforce(baseSec <= sections.length, "Invalid base section index");
                if (baseSec == 0)
                    auto baseFrame = getWordLE(data);
                while (data.length)
                {
                    auto group = baseGroup;
                    auto sec = baseSec;
                    auto length = getByte(data);
                    auto name = getBytes(data, length);
                    auto offset = off16 ? getWordLE(data) : getDwordLE(data);
                    auto type = getIndex(data);
                    if (sec)
                    {
                        symtab.add(new PublicSymbol(sections[sec-1], name, offset));
                    } else {
                        symtab.add(new AbsoluteSymbol(name, offset));
                    }
                    //writeln("PUBDEF name:", cast(string)name, " ", sec ? cast(string)sections[sec-1].name : "__abs__", "+", offset);
                }
                enforce(data.length == 0, "Corrupt PUBDEF record");
                break;
            case OmfRecordType.COMDAT16:
            case OmfRecordType.COMDAT32:
                auto off16 = (r.type == OmfRecordType.COMDAT16);
                auto data = r.data;
                auto flags = getByte(data);
                auto isIterated = (flags & 0x2) != 0;
                auto isLocal = (flags & 0x4) != 0;
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
                ushort baseSec;
                if ((attributes & 0x0F) == 0x00)
                {
                    baseGroup = getIndex(data);
                    enforce(baseGroup <= groups.length, "Invalid base group index");
                    baseSec = getIndex(data);
                    enforce(baseSec <= sections.length, "Invalid base section index");
                    if (baseSec == 0)
                        auto baseFrame = getWordLE(data);
                } else
                    assert(0);
                auto name = getIndex(data);
                auto sec = sections[baseSec-1];
                SectionAlign secalign;
                switch(alignment)
                {
                case 0: secalign = sec.secalign;            break;
                case 1: secalign = SectionAlign.align_1;    break;
                case 2: secalign = SectionAlign.align_2;    break;
                case 3: secalign = SectionAlign.align_16;   break;
                case 4: secalign = SectionAlign.align_page; break;
                case 5: secalign = SectionAlign.align_4;    break;
                default:
                    enforce(false, "Invalid alignment value");
                    break;
                }
                //auto length = data.length;
                //auto xsec = new Section(sec.name ~ '$' ~ names[name-1], sec.secclass, secalign, length);
                //auto csec = sectab.add(xsec);
                if (flags & 1)
                {
                    //writeln("Continue comdat ", cast(string)(sec.name ~ '$' ~ names[name-1]), " length:", data.length);
                    /*foreach(v; data)
                        writef("%.2X ", v);
                    writeln();*/
                    // Modify previous section
                    auto sym = symtab.searchName(names[name-1]);
                    assert(sym);
                    assert(cast(ComdatSymbol)sym);
                    auto csec = (cast(ComdatSymbol)sym).sec;
                    enforce(!isIterated);
                    //writeln(offset, "..", offset + data.length, "  ", csec.length);
                    //enforce(offset == csec.length, "Overlapping or gapped comdats are not supported");
                    auto p = csec.container;
                    //enforce(offset == p.length, "Overlapping or gapped comdats are not supported");
                    enforce(p.members.length == 1);
                    enforce(p.length == csec.length);
                    csec.length = max(offset + data.length, csec.length);
                    p.length = csec.length;
                }
                else
                {
                    enforce(offset == 0);
                    auto csec = new Section(sec.name ~ '$' ~ names[name-1], sec.secclass, sec.secalign, data.length);
                    sectab.add(csec);
                    auto sym = new ComdatSymbol(csec, names[name-1], offset, comdat, isLocal);
                    symtab.add(sym);
                    //writeln("Start comdat ", cast(string)(sec.name ~ '$' ~ names[name-1]), " length:", data.length);
                    /*foreach(v; data)
                        writef("%.2X ", v);
                    writeln();*/
                }
                //writeln(flags, ' ', attributes, ' ', comdat);
                //writeln("COMDAT name:", cast(string)names[name-1], " ", cast(string)sections[baseSec-1].name, isLocal ? " local" : "");
                break;
            case OmfRecordType.EXTDEF:
                auto data = r.data;
                while (data.length)
                {
                    auto length = getByte(data);
                    auto name = getBytes(data, length);
                    auto type = getIndex(data);
                    if (name.startsWith("__imp_"))
                    {
                        symtab.add(new ExternSymbol(name[6..$]));
                        //writeln("EXTDEF name:", cast(string)name[6..$]);
                    }
                    auto sym = new ExternSymbol(name);
                    symtab.add(sym);
                    externs ~= name;
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
                    auto sym = new ExternSymbol(names[name-1]);
                    symtab.add(sym);
                    externs ~= names[name-1];
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

                    auto sym = new ComdefSymbol(name, length);
                    symtab.add(sym);
                    externs ~= name;
                    //writeln("COMDEF name:", cast(string)name);
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
            case OmfRecordType.LINNUM:
            case OmfRecordType.LINSYM:
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
                if (hasStart)
                {
                    auto fixdata = getByte(data);
                    auto F = (fixdata & 0x80) != 0;
                    auto frametype = (fixdata & 0x70) >> 4;
                    auto T = (fixdata & 0x08) != 0;
                    auto P = (fixdata & 0x04) != 0;
                    auto Targt = (fixdata & 0x03);
                    ushort frame;
                    if (!F)
                        frame = getIndex(data);
                    ushort target;
                    if (!T)
                        target = getIndex(data);
                    uint displacement;
                    if (!P)
                        displacement = getDwordLE(data);
                    enforce(!P, "Displacement must be present for start address");
                    enforce(!F);
                    enforce(!T);
                    enforce(frametype == 1);
                    enforce(Targt == 2);
                    enforce(frame == 1, "Only FLAT group is supported");
                    enforce(displacement == 0, "Displacement is not supported for the start address");
                    //writeln(target, ' ', displacement);
                    //writeln(cast(string)externs[target-1]);
                    symtab.setEntry(externs[target-1]);
                }
                enforce(data.length == 0, "Corrupt MODEND record");
                modend = true;
                break;
            default:
                enforce(false, "Unsupported record type: " ~ to!string(r.type));
                break;
            }
        }
        symtab.checkUnresolved();
        symtab.merge();
    }
    override void loadData(uint tlsBase)
    {
        f.seek(0);
        auto modend = false;

        uint defOffset;
        Section defSection;
        bool defIterate;
        immutable(ubyte)[] defData;
        bool defOff16;

        while (!f.empty() && !modend)
        {
            auto r = loadRecord();
            auto data = r.data;
            switch(r.type)
            {
            case OmfRecordType.THEADR:
                auto len = r.data[0];
                enforce(len == r.data.length - 1, "Corrupt THEADR record");
                debug(OMFDATA) writeln("Module: ", cast(string)r.data[1..$]);
                break;
            case OmfRecordType.LLNAMES:
            case OmfRecordType.LNAMES:
            case OmfRecordType.COMENT:
            case OmfRecordType.SEGDEF16:
            case OmfRecordType.SEGDEF32:
            case OmfRecordType.GRPDEF:
            case OmfRecordType.PUBDEF16:
            case OmfRecordType.PUBDEF32:
            case OmfRecordType.EXTDEF:
            case OmfRecordType.CEXTDEF:
            case OmfRecordType.COMDEF:
                // Pass 1 records are skipped
                break;
            case OmfRecordType.ALIAS:
            case OmfRecordType.LPUBDEF:
            case OmfRecordType.LCOMDEF:
            case OmfRecordType.LEXTDEF:
                enforce(false, "Record type " ~ to!string(r.type) ~ " not implemented");
                break;
            case OmfRecordType.COMDAT16:
            case OmfRecordType.COMDAT32:
                writeRecord(defOffset, defSection, defIterate, defData, defOff16);
                auto off16 = (r.type == OmfRecordType.COMDAT16);
                auto flags = getByte(data);
                auto isLocal = (flags & 0x4) != 0;
                auto isIterated = (flags & 0x2) != 0;
                assert(flags < 8);
                auto attributes = getByte(data);
                assert((attributes & 0xF0) <= 0x10);
                assert((attributes & 0x0F) == 0x00);
                auto alignment = getByte(data);
                auto offset = off16 ? getWordLE(data) : getDwordLE(data);
                auto type = getIndex(data);
                auto baseGroup = getIndex(data);
                enforce(baseGroup <= groups.length, "Invalid base group index");
                auto baseSec = getIndex(data);
                enforce(baseSec <= sections.length, "Invalid base section index");
                if (baseSec == 0)
                    auto baseFrame = getWordLE(data);
                auto name = getIndex(data);
                auto sym = symtab.deepSearch(names[name-1]);
                assert(sym);
                assert(cast(ComdatSymbol)sym);
                auto sec = (cast(ComdatSymbol)sym).sec;
                defOffset = offset;
                defSection = sec;
                defIterate = isIterated;
                defData = data;
                defOff16 = off16;
                debug(OMFDATA) writeln("COMDAT ", cast(string)sec.fullname, '+', offset, " ", data.length, " bytes");
                debug(OMFDATA) writeln(sec.base, ' ', sec.container.base, ' ', flags, ' ', sec.container.members.length);
                debug(OMFDATA) writefln("[%(%.2X %)]", data);
                break;
            case OmfRecordType.LEDATA16:
            case OmfRecordType.LEDATA32:
                writeRecord(defOffset, defSection, defIterate, defData, defOff16);
                auto off16 = (r.type == OmfRecordType.LEDATA16);
                auto index = getIndex(data);
                enforce(index <= sections.length, "Invalid section index");
                defOffset = off16 ? getWordLE(data) : getDwordLE(data);
                defSection = sections[index-1];
                defIterate = false;
                defData = data;
                defOff16 = off16;
                debug(OMFDATA) writeln("LEDATA ", cast(string)defSection.fullname, '+', defOffset, " ", data.length, " bytes");
                debug(OMFDATA) writefln("[%(%.2X %)]", data);
                break;
            case OmfRecordType.LIDATA16:
            case OmfRecordType.LIDATA32:
                writeRecord(defOffset, defSection, defIterate, defData, defOff16);
                auto off16 = (r.type == OmfRecordType.LIDATA16);
                auto index = getIndex(data);
                enforce(index <= sections.length, "Invalid section index");
                defOffset = off16 ? getWordLE(data) : getDwordLE(data);
                defSection = sections[index-1];
                defIterate = true;
                defData = data;
                defOff16 = off16;
                debug(OMFDATA) writeln("LIDATA ", cast(string)defSection.fullname, '+', defOffset, " ", data.length, " bytes");
                debug(OMFDATA) writefln("[%(%.2X %)]", data);
                break;
            case OmfRecordType.FIXUPP16:
            case OmfRecordType.FIXUPP32:
                while (data.length)
                {
                    if ((data[0] & 0x80) == 0)
                    {
                        writeln("THREAD");
                        auto head = getByte(data);
                        auto index = getIndex(data);
                    }
                    else
                    {
                        auto locat = getWordBE(data);
                        auto M = (locat & 0x4000) != 0;
                        auto location = (locat & 0x3C00) >> 10;
                        auto offset = (locat & 0x3FF);
                        auto fixdata = getByte(data);
                        auto F = (fixdata & 0x80) != 0;
                        auto frametype = (fixdata & 0x70) >> 4;
                        auto T = (fixdata & 0x08) != 0;
                        auto P = (fixdata & 0x04) != 0;
                        auto Targt = (fixdata & 0x03);
                        ushort frame;
                        if (!F && (frametype == 0 || frametype == 1 || frametype == 2))
                            frame = getIndex(data);
                        ushort target;
                        if (!T)
                            target = getIndex(data);
                        uint displacement;
                        if (P == 0)
                            displacement = getDwordLE(data);

                        //writeln("FIXUP M:", M, " location:", location, " offset:", offset, " F:", F, " frametype:", frametype);
                        //writeln("      T:", T, " P:", P, " Targt: ", Targt, " frame:", frame, " target:", target, " disp:", displacement);
                        enforce(!F, "Frame threads are not supported");
                        enforce(!T, "Target threads are not supported");
                        //writeln("F", frametype, " T", (P << 2) | Targt);
                        uint targetBase;
                        uint targetAddress;
                        //writeln(location, ' ', displacement, ' ', offset);
                        //writeln("in ", cast(string)defSection.fullname);
                        switch(Targt)
                        {
                        case 0:
                            debug(fixup) writeln("\nFIXUP target Segment relative (", cast(string)sections[target-1].name, ")");
                            auto targetSec = sections[target-1];
                            targetBase = targetSec.base;
                            targetAddress = targetBase + displacement;
                            break;
                        case 2:
                            //writeln(externs.length, ' ', target);
                            //writeln(cast(string[])externs);
                            debug(fixup) writeln("\nFIXUP target Extern relative (", cast(string)externs[target-1], ")");
                            auto extname = externs[target-1];
                            auto sym = symtab.deepSearch(extname);
                            debug(fixup) sym.dump();
                            assert(sym, cast(string)extname);
                            targetBase = sym.getAddress();
                            targetAddress = targetBase + displacement;
                            break;
                        default:
                            enforce(false, "Group-relative targets are not supported");
                            break;
                        }
                        uint baseAddress;
                        switch(frametype)
                        {
                        case 0:
                            debug(fixup) writeln("FIXUP frame  Segment relative (", cast(string)sections[frame-1].name, ")");
                            baseAddress = sections[frame-1].base;
                            break;
                        case 1:
                            debug(fixup) writeln("FIXUP frame  Group relative (", cast(string)names[groups[frame-1].name-1], ")");
                            enforce(names[groups[frame-1].name-1] == "FLAT");
                            baseAddress = 0;
                            break;
                        case 5: // used for eh tables
                            debug(fixup) writeln("FIXUP frame  Target X relative");
                            baseAddress = targetBase;
                            break;
                        default:
                            assert(0);
                        }
                        if (!M)
                        {
                            // self-relative
                            //enforce(baseAddress == 0);
                            debug(fixup) writeln("Relative");
                            baseAddress = defSection.base + offset + 4;
                        }
                        else
                        {
                            debug(fixup) writeln("Direct");
                            baseAddress = 0;
                        }
                        // Warning: incoming casts: we know defData is unique
                        auto xdata = cast()defData;
                        switch(location)
                        {
                        case 9: // 32-bit offset
                            debug(fixup) writefln("### FIXUP 32b (0x%.4X) 0x%.8X -> 0x%.8X + 0x%.8X", offset, baseAddress, targetBase, displacement);
                            enforce(offset + 4 <= xdata.length);
                            (cast(uint[])xdata[offset..offset+4])[0] += targetAddress - baseAddress;
                            break;
                        case 10: // tls offset?
                            enforce(tlsBase != -1);
                            debug(fixup) writefln("### FIXUP tls (0x%.4X) 0x%.8X -> 0x%.8X + 0x%.8X", offset, tlsBase, targetBase, displacement);
                            enforce(offset + 4 <= xdata.length);
                            (cast(uint[])xdata[offset..offset+4])[0] += targetAddress - tlsBase;
                            break;
                        case 11: // seg-offset
                            assert(0);
                            debug(fixup) writefln("### FIXUP deb (0x%.4X) 0x%.8X -> 0x%.8X + 0x%.8X", offset, baseAddress, targetBase, displacement);
                            enforce(offset + 5 <= xdata.length);
                            break;
                        default:
                            enforce(false, "Only some weirdly selected and undocumented offset fixups are supported");
                            break;
                        }
                    }
                }
                enforce(data.length == 0, "Corrupt FIXUPP record");
                break;
            case OmfRecordType.LINNUM:
                writeln("LINNUM");
                assert(0);
                break;
            case OmfRecordType.LINSYM:
                writeln("LINSYM");
                assert(0);
                break;
            case OmfRecordType.MODEND16:
            case OmfRecordType.MODEND32:
                modend = true;
                writeRecord(defOffset, defSection, defIterate, defData, defOff16);
                break;
            default:
                enforce(false, "Unsupported record type: " ~ to!string(r.type));
                break;
            }
        }
    }
private:
    void writeRecord(uint offset, Section sec, bool iterate, immutable(ubyte)[] data, bool off16)
    {
        //enforce(sec.secclass != SectionClass.BSS, "Error: Data defined for uninitialized block");
        if (!data.length)
            return;
        assert(sec);
        if (!sec.length)
            return;
        if (sec.secclass == SectionClass.BSS)
            return;
        if (sec.secclass == SectionClass.DEBSYM)
            return;
        if (iterate)
        {
            void readDataBlock(immutable(ubyte)[] data)
            {
                auto repCount = off16 ? getWordLE(data) : getDwordLE(data);
                auto blockCount = getWordLE(data);
                //writeln("rep: ", repCount);
                //writeln("blk: ", blockCount);
                immutable(ubyte)[] repdata;
                if (!blockCount)
                {
                    repdata = getString(data);
                    //writeln("***********************************");
                    //writeln(offset, ": ", repdata, " * ", repCount);
                    foreach(i; 0..repCount)
                    {
                        //writeln(cast(string)sec.fullname);
                        //writeln(offset, " + ", repdata.length, " <= ", sec.length);
                        //writeln(sec.data.length);
                        enforce(offset + repdata.length <= sec.length, "Data is too big for section");
                        sec.data[offset..offset + repdata.length] = repdata;
                        offset += repdata.length;
                    }
                    //writeln("LIDATA ", repdata, " * ", repCount);
                }
                else
                {
                    assert(blockCount == 1);
                    foreach(i; 0..repCount)
                        readDataBlock(data);
                }
            }
            readDataBlock(data);
        } else {
            //writeln(cast(string)sec.fullname);
            //writeln(offset, ' ', data.length, ' ', sec.length);
            //writeBytes(data);
            enforce(offset + data.length <= sec.length, "Data is too big for section");
            sec.data[offset..offset + data.length] = data[];
        }
    }
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
    SectionClass getSectionClass(immutable(ubyte)[] name)
    {
        SectionClass secclass;
        with(SectionClass)
        switch(cast(string)name)
        {
        case "CODE":   secclass = Code;   break;
        case "DATA":   secclass = Data;   break;
        case "CONST":  secclass = Const;  break;
        case "BSS":    secclass = BSS;    break;
        case "tls":    secclass = TLS;    break;
        case "ENDBSS": secclass = BSS;    break;
        case "STACK":  secclass = STACK;  break;
        case "DEBSYM": secclass = DEBSYM; break;
        case "DEBTYP": secclass = DEBSYM; break;
        default:
            enforce(false, "Unknown section class: " ~ cast(string)name);
            break;
        }
        return secclass;
    }
}

void writeBytes(in ubyte[] data)
{
    write("[");
    foreach(v; data)
        writef("%.2X ", v);
    writeln("]");
}
