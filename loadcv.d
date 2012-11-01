
import std.conv;
import std.stdio;
import std.string;

import codeview;
import datafile;
import debuginfo;

private:

debug=LOADCV;

void debugfln(T...)(T args)
{
    debug(LOADCV)
    {
        static if (T.length)
            writefln(args);
        else
            writeln();
    }
}

public:

void loadCodeView(DataFile f, uint lfaBase, DebugInfo di)
{
    f.seek(lfaBase);
    auto cvh = f.read!uint();
    assert(cvh == CV41_SIG, "Only CV41 is supported");
    debugfln("Found CV41 debug information");
    auto lfoDir = f.read!uint();

    f.seek(lfaBase + lfoDir);
    auto dirheader = f.read!CV_DIRHEADER();
    assert(dirheader.cbDirHeader == CV_DIRHEADER.sizeof);
    assert(dirheader.cbDirEntry == CV_DIRENTRY.sizeof);
    assert(dirheader.lfoNextDir == 0);
    assert(dirheader.flags == 0);
    debugfln("Found %d subsections", dirheader.cDir);

    uint[] typeoffsets;
    DebugType[] types;
    typeoffsets.length = 4096;
    types.length = 4096;
    types[T_VOID] = new DebugTypeBasic(BT_VOID);
    types[T_32PVOID] = new DebugTypePointer(types[T_VOID]);
    types[T_RCHAR] = new DebugTypeBasic(BT_CHAR);
    types[T_32PRCHAR] = new DebugTypePointer(types[T_RCHAR]);
    types[T_WCHAR] = new DebugTypeBasic(BT_WCHAR);
    types[0x78] = new DebugTypeBasic(BT_DCHAR);
    types[T_CHAR] = new DebugTypeBasic(BT_BYTE);
    types[T_UCHAR] = new DebugTypeBasic(BT_UBYTE);
    types[T_SHORT] = new DebugTypeBasic(BT_SHORT);
    types[T_USHORT] = new DebugTypeBasic(BT_USHORT);
    types[T_INT4] = new DebugTypeBasic(BT_INT);
    types[T_UINT4] = new DebugTypeBasic(BT_UINT);
    types[T_QUAD] = new DebugTypeBasic(BT_LONG);
    types[T_UQUAD] = new DebugTypeBasic(BT_ULONG);
    types[T_BOOL08] = new DebugTypeBasic(BT_BOOL);
    types[T_REAL32] = new DebugTypeBasic(BT_FLOAT);
    types[T_REAL64] = new DebugTypeBasic(BT_DOUBLE);
    types[T_REAL80] = new DebugTypeBasic(BT_REAL);
    types[T_CPLX32] = new DebugTypeBasic(BT_CFLOAT);
    types[T_CPLX64] = new DebugTypeBasic(BT_CDOUBLE);
    types[T_CPLX80] = new DebugTypeBasic(BT_CREAL);

    foreach(i; 0..dirheader.cDir)
    {
        f.seek(lfaBase + lfoDir + CV_DIRHEADER.sizeof + CV_DIRENTRY.sizeof * i);
        auto entry = f.read!CV_DIRENTRY();
        debugfln("Entry: 0x%.4X 0x%.4X 0x%.8X 0x%.8X", entry.subsection, entry.iMod, lfaBase + entry.lfo, entry.cb);
        f.seek(lfaBase + entry.lfo);
        switch(entry.subsection)
        {
        case sstModule:
            auto ovlNumber = f.read!ushort();
            assert(ovlNumber == 0, "Overlays are not supported");
            auto iLib = f.read!ushort();
            auto cSeg = f.read!ushort();
            auto Style = f.read!ushort();
            assert(Style == ('V' << 8 | 'C'), "Only CV is supported");
            foreach(j; 0..cSeg)
            {
                auto Seg = f.read!ushort();
                auto pad = f.read!ushort();
                auto offset = f.read!uint();
                auto cbSeg = f.read!uint();
            }
            auto name = f.readPreString();
            debugfln("CV sstModule: %s", cast(string)name);
            if (iLib)
                debugfln("\tFrom lib #%d", iLib);
            di.addModule(new DebugModule(name, iLib));
            break;
        case sstSrcModule:
            debugfln("CV sstSrcModule");

            // Module header
            auto cFile = f.read!ushort();
            auto cSeg = f.read!ushort();
            debugfln("\t%d files", cFile);
            debugfln("\t%d segments", cSeg);
            auto filebase = new uint[](cFile);
            foreach(j; 0..cFile)
                filebase[j] = f.read!uint();
            auto segstart = new uint[](cSeg);
            auto segend = new uint[](cSeg);
            auto segindex = new ushort[](cSeg);
            foreach(j; 0..cSeg)
            {
                segstart[j] = f.read!uint();
                segend[j] = f.read!uint();
            }
            foreach(j; 0..cSeg)
                segindex[j] = f.read!ushort();
            f.alignto(4);

            foreach(j; 0..cSeg)
            {
                debugfln("Seg %d (%d) at 0x%.8X..0x%.8X", j, segindex[j], segstart[j], segend[j]);
            }

            // File Info
            foreach(j, fileoff; filebase)
            {
                debugfln("File %d at 0x%.8X", j, fileoff);
                f.seek(lfaBase + entry.lfo + fileoff);
                auto xcSeg = f.read!ushort();
                assert(f.read!ushort() == 0);
                auto baseSrcLn = cast(immutable uint[])f.readBytes(uint.sizeof * xcSeg);
                auto startend = cast(immutable uint[2][])f.readBytes((uint[2]).sizeof * xcSeg);
                auto name = f.readPreString();
                debugfln("\tName: %s", cast(string)name);
                debugfln("\tLine maps: %(0x%.8X, %)", baseSrcLn);
                debugfln("\tSegs: %(%(0x%.8X..%), %)", startend);

                auto s = new DebugSourceFile(name);

                foreach(k, off; baseSrcLn)
                {
                    f.seek(lfaBase + entry.lfo + off);
                    debugfln("\tLine numbers in block %d:", k);
                    auto Segi = f.read!ushort();
                    auto cPair = f.read!ushort();
                    auto offset = cast(uint[])f.readBytes(uint.sizeof*cPair);
                    auto linenum = cast(ushort[])f.readBytes(ushort.sizeof*cPair);

                    BlockInfo bi;
                    bi.segid = Segi;
                    bi.start = startend[k][0];
                    bi.end = startend[k][1];

                    foreach(l; 0..cPair)
                    {
                        debugfln("\t\t0x%.8X: %d Seg #%d", offset[l], linenum[l], Segi);
                        bi.linnums ~= LineInfo(offset[l], linenum[l]);
                    }
                    s.addBlock(bi);
                }
                di.addSourceFile(s);
            }
            break;
        case sstLibraries:
            debugfln("CV Library list:");
            auto len = f.read!ubyte();
            assert(len == 0);
            auto count = 1;
            while ((len = f.read!ubyte()) != 0)
            {
                auto name = f.readBytes(len);
                debugfln("\tLib #%d: %s", count, cast(string)name);
                count++;
                di.addLibrary(new DebugLibrary(name));
            }
            break;
        case sstGlobalPub: // List of all public symbols
            auto symhash = f.read!ushort();
            auto addrhash = f.read!ushort();
            debugfln("CV Global Public Symbols:");
            //debugfln("\tSymbol hash: 0x%.4X", symhash);
            //debugfln("\tAddress hash: 0x%.4X", addrhash);
            auto cbSymbol = f.read!uint();
            auto cbSymHash = f.read!uint();
            auto cbAddrHash = f.read!uint();
            //debugfln("\tSymbols: 0x%X bytes", cbSymbol);
            //debugfln("\tcbSymHash: 0x%X bytes", cbSymHash);
            //debugfln("\tcbAddrHash: 0x%X bytes", cbAddrHash);
            auto symstart = f.tell();
            while(f.tell() < symstart + cbSymbol)
            {
                f.alignto(4);
                loadSymbol(f, di);
            }
            assert(f.tell() == symstart + cbSymbol);
            break;
        case sstGlobalSym: // List of all non-public symbols
            debugfln("CV Global Symbols:");
            auto symhash = f.read!ushort();
            auto addrhash = f.read!ushort();
            auto cbSymbol = f.read!uint();
            auto cbSymHash = f.read!uint();
            auto cbAddrHash = f.read!uint();
            auto symstart = f.tell();
            while(f.tell() < symstart + cbSymbol)
            {
                f.alignto(4);
                loadSymbol(f, di);
            }
            assert(f.tell() == symstart + cbSymbol);
            break;
        case sstGlobalTypes:
            debugfln("CV Global Types:");
            auto flags = f.read!uint();
            assert(flags == 0x00000001);
            auto cType = f.read!uint();
            auto offType = new uint[](cType);
            foreach(j, ref off; offType)
                off = f.read!uint();
            auto typestart = f.tell();
            foreach(j, ref off; offType)
            {
                f.seek(typestart + off);
                types ~= loadTypeLeaf(f);
            }
            foreach(j, ref off; offType)
            {
                f.seek(typestart + off);
                assert(types[0x1000+j]);
                types[0x1000+j] = types[0x1000+j].resolve(types);
            }
            break;
        case sstFileIndex:
            debugfln("CV File Index:");
            debugfln("%.8X", f.tell());
            auto cMod = f.read!ushort();
            auto cRef = f.read!ushort();
            auto ModStart = cast(ushort[])f.readBytes(ushort.sizeof * cMod);
            auto cRefCnt = cast(ushort[])f.readBytes(ushort.sizeof * cMod);
            auto NameRef = cast(uint[])f.readBytes(uint.sizeof * cRef);
            auto nametable = f.tell();
            foreach(j; 0..cMod)
            {
                debugfln("\tModule %d:", j+1);
                auto p = ModStart[j];
                foreach(k; 0..cRefCnt[j])
                {
                    f.seek(nametable + NameRef[p + k]);
                    auto name = f.readPreString();
                    debugfln("\t\tSourcefile: %s", cast(string)name);
                    di.addModuleSource(j+1, name);
                }
            }
            break;
        case sstSegMap:
            debugfln("CV Segment Map:");
            auto cSeg = f.read!ushort();
            auto cSegLog = f.read!ushort();
            auto SegDesc = new CV_SEGDESC[](cSegLog);
            debugfln("\tcSeg: %d", cSeg);
            debugfln("\tcSegLog: %d", cSegLog);
            foreach(j, ref v; SegDesc)
                v = f.read!CV_SEGDESC();
            foreach(j, ref v; SegDesc)
            {
                debugfln("\tSegment %d:", j+1);
                debugfln("\t\tFlags: 0x%.4X", v.flags);
                debugfln("\t\tOverlay: %d", v.ovl);
                debugfln("\t\tGroup: %d", v.group);
                debugfln("\t\tFrame: %d", v.frame);
                debugfln("\t\tSeg name: 0x%.4X", v.iSegName);
                debugfln("\t\tClass name: 0x%.4X", v.iClassName);
                debugfln("\t\tOffset: 0x%.8X", v.offset);
                debugfln("\t\tLength: 0x%.8X", v.cbseg);
                assert(v.ovl == 0);
                assert(v.iClassName == 0xFFFF);
                assert(v.offset == 0);
                auto fRead = (v.flags & 0x1) != 0;
                auto fWrite = (v.flags & 0x2) != 0;
                auto fExecute = (v.flags & 0x4) != 0;
                auto f32Bit = (v.flags & 0x8) != 0;
                auto fSel = (v.flags & 0x100) != 0;
                auto fAbs = (v.flags & 0x200) != 0;
                auto fGroup = (v.flags & 0x1000) != 0;
                assert(f32Bit && fSel && !fAbs && !fGroup);
                di.addSegment(new DebugSegment(v.cbseg));
            }
            break;
        case sstSegName:
            debugfln("CV Segment Names:");
            auto count = 0;
            while (f.tell() < lfaBase + entry.lfo + entry.cb)
            {
                count++;
                auto name = f.readZString();
                debugfln("\tSegment %d: %s", count, cast(string)name);
                di.setSegmentName(count, name);
            }
            break;
        case sstAlignSym:
            debugfln("CV Aligned Symbols:");
            auto sig = f.read!uint();
            assert(sig == 0x00000001);
            while(f.tell() < lfaBase + entry.lfo + entry.cb)
            {
                f.alignto(4);
                loadSymbol(f, di);
            }
            break;
        case sstStaticSym:
            debugfln("CV Static Symbol:");
            break;
        default:
            debugfln("Unhandled CV subsection type 0x%.3X", entry.subsection);
            assert(0);
        }
    }
}

void loadSymbol(DataFile f, DebugInfo di)
{
    auto len = f.read!ushort();
    auto symtype = f.read!ushort();
    f.seek(f.tell() + len - 2);
}

DebugType loadTypeLeaf(DataFile f)
{
    DebugType t;
    auto length = f.read!ushort();
    auto type = f.read!ushort();
    switch (type)
    {
    case LF_MODIFIER:
        debugfln("\tLF_MODIFIER");
        auto attr = f.read!ushort();
        auto ptype = f.read!ushort();
        debugfln("\t\ttype: %s", decodeCVType(ptype));
        debugfln("\t\tattr:%s%s%s", (attr & 0x1) ? " const" : "", (attr & 0x2) ? " volatile" : "", (attr & 0x4) ? " unaligned" : "");
        t = new DebugTypeIndex(ptype);
        if (attr & 0x1) t.modifiers |= M_CONST;
        if (attr & 0x2) t.modifiers |= M_VOLATILE;
        if (attr & 0x4) t.modifiers |= M_UNALIGNED;
        break;

    case LF_OEM:
        debugfln("\tLF_OEM");
        auto OEMid = f.read!ushort();
        auto recOEM = f.read!ushort();
        auto count = f.read!ushort();
        auto indices = cast(ushort[])f.readBytes(ushort.sizeof * count);
        debugfln("\t\tOEM id: 0x%.4X", OEMid);
        debugfln("\t\ttype id: 0x%.4X", recOEM);
        foreach(ind; indices)
            debugfln("\t\tsubtype: %s", decodeCVType(ind));
        assert(OEMid == 0x0042);
        switch (recOEM == 0x0001)
        {
        case 0x0001: // Dynamic array
            assert(count == 2);
            assert(indices[0] == T_LONG);
            t = new DebugTypeIndex(indices[1]);
            t = new DebugTypeDArray(t);
            break;
        default:
            assert(0, "Unrecognized OEM leaf type");
        }
        break;

    case LF_ARGLIST:
        debugfln("\tLF_ARGLIST");
        auto count = f.read!ushort();
        debugfln("\t\t%d args", count);
        DebugType[] ts;
        foreach(i; 0..count)
        {
            auto typind = f.read!ushort();
            debugfln("\t\t%s", decodeCVType(typind));
            ts ~= new DebugTypeIndex(typind);
        }
        t = new DebugTypeList(ts);
        break;

    case LF_PROCEDURE:
        debugfln("\tLF_PROCEDURE");
        auto rettype = f.read!ushort();
        auto cc = f.read!ubyte();
        auto reserved = f.read!ubyte();
        auto argcount = f.read!ushort();
        auto arglist = f.read!ushort();
        debugfln("\t\tReturn type: %s", decodeCVType(rettype));
        debugfln("\t\tCalling convention: %d", cc);
        debugfln("\t\tArg count: %d", argcount);
        debugfln("\t\tArg list: %s", decodeCVType(arglist));
        auto tr = new DebugTypeIndex(rettype);
        auto at = new DebugTypeIndex(arglist);
        t = new DebugTypeFunction(tr, at, null, null);
        break;

    case LF_POINTER:
        debugfln("\tLF_POINTER");
        auto attr = f.read!ushort();
        auto ptype = f.read!ushort();
        debugfln("\t\ttype: %s", decodeCVType(ptype));
        debugfln("\t\tattr: %.4X", attr);
        auto size = attr & 0x1F;
        assert(size == 0xA);
        auto ptrmode = (attr >> 5) & 0x3;
        t = new DebugTypeIndex(ptype);
        switch(ptrmode)
        {
        case 0:
            debugfln("\t\tmode: pointer");
            t = new DebugTypePointer(t);
            break;
        case 1:
            debugfln("\t\tmode: reference");
            t = new DebugTypeReference(t);
            break;
        default:
            assert(0);
        }
        assert(!(attr & 0x100));
        if (attr & 0x200) t.modifiers |= M_VOLATILE;
        if (attr & 0x400) t.modifiers |= M_CONST;
        if (attr & 0x800) t.modifiers |= M_UNALIGNED;
        break;

    case LF_STRUCTURE:
    case LF_CLASS:
        if (type == LF_STRUCTURE)
            debugfln("\tLF_STRUCTURE");
        else
            debugfln("\tLF_CLASS");
        auto count = f.read!ushort();
        auto ftype = f.read!ushort();
        auto prop = f.read!ushort();
        auto dlist = f.read!ushort();
        auto vtbl = f.read!ushort();
        auto size = readNumericLeaf(f);
        auto name = f.readPreString();
        debugfln("\t\tName: %s", cast(string)name);
        debugfln("\t\tMembers: %d", count);
        debugfln("\t\tFields: %s", decodeCVType(ftype));
        debugfln("\t\tProperties: %.4X", prop);
        debugfln("\t\tDerived: %s", decodeCVType(dlist));
        debugfln("\t\tVtbl: %s", decodeCVType(vtbl));
        debugfln("\t\tsizeof: %d", size);
        DebugType fields;
        if (count)
            fields = new DebugTypeIndex(ftype);
        if (type == LF_STRUCTURE)
            t = new DebugTypeStruct(name, fields);
        else
            t = new DebugTypeClass(name, fields);
        break;

    case LF_ARRAY:
        debugfln("\tLF_ARRAY");
        auto etype = f.read!ushort();
        auto itype = f.read!ushort();
        auto dim = f.read!ushort();
        auto name = f.readPreString();
        debugfln("\t\tName: %s", name);
        debugfln("\t\tElement type: %s", decodeCVType(etype));
        debugfln("\t\tIndex type: %s", decodeCVType(itype));
        debugfln("\t\tLength: %d", dim);
        assert(itype == T_LONG);
        auto et = new DebugTypeIndex(etype);
        t = new DebugTypeArray(et);
        break;

    case LF_FIELDLIST:
        debugfln("\tLF_FIELDLIST");
        DebugType[] ts;
        while ((f.peek!ushort() & 0xFF00) == 0x0400)
        {
            auto fdtype = f.read!ushort();
            switch (fdtype)
            {
            case LF_MEMBER:
                debugfln("\t\tLF_MEMBER");
                auto ftype = f.read!ushort();
                auto attr = f.read!ushort();
                auto offset = readNumericLeaf(f).as!uint();
                auto name = f.readPreString();
                debugfln("\t\t\tMember: %s (+%s) (%s)", cast(string)name, offset, decodeAttrib(attr));
                auto ft = new DebugTypeIndex(ftype);
                ts ~= new DebugTypeField(ft, offset, name);
                break;
            case LF_METHOD:
                debugfln("\t\tLF_METHOD");
                auto count = f.read!ushort();
                auto mlist = f.read!ushort();
                auto name = f.readPreString();
                debugfln("\t\t\tMember functions: %s (%d)", cast(string)name, count);
                auto ft = new DebugTypeIndex(mlist);
                ts ~= new DebugTypeField(ft, -1, name);
                break;
            case LF_BCLASS:
                debugfln("\t\tLF_BCLASS");
                auto ctype = f.read!ushort();
                auto attr = f.read!ushort();
                debugfln("\t\t\tBase class: %s - %s", decodeCVType(ctype), decodeAttrib(attr));
                auto ct = new DebugTypeIndex(ctype);
                ts ~= new DebugTypeBaseClass(ct, attr);
                break;
            case LF_VFUNCTAB:
                debugfln("\t\tLF_VFUNCTAB");
                auto vtype = f.read!ushort();
                debugfln("\t\t\tVtbl: %s", decodeCVType(vtype));
                ts ~= new DebugTypeIndex(vtype);
                break;
            case LF_ENUMERATE:
                debugfln("\t\tLF_ENUMERATE");
                auto attr = f.read!ushort();
                auto value = readNumericLeaf(f);
                auto name = f.readPreString();
                debugfln("\t\t\tEnum member: %s = %s (%s)", cast(string)name, value, decodeAttrib(attr));
                ts ~= new DebugTypeEnumMember(name, value, attr);
                break;
            case LF_STMEMBER:
                debugfln("\t\tLF_STMEMBER");
                auto ftype = f.read!ushort();
                auto attr = f.read!ushort();
                auto name = f.readPreString();
                debugfln("\t\t\tStatic member: %s (%s)", cast(string)name, decodeAttrib(attr));
                auto ft = new DebugTypeIndex(ftype);
                ts ~= new DebugTypeField(ft, -1, name);
                break;
            case LF_FRIENDCLS:
                debugfln("\t\tLF_FRIENDCLS");
                auto ctype = f.read!ushort();
                debugfln("\t\t\tFriend class: %s", decodeCVType(ctype));
                ts ~= new DebugTypeIndex(ctype);
                break;
            case LF_NESTEDTYPE:
                debugfln("\t\tLF_NESTEDTYPE");
                auto ctype = f.read!ushort();
                auto name = f.readPreString();
                debugfln("\t\t\tNested type: %s - %s", cast(string)name, decodeCVType(ctype));
                auto ct = new DebugTypeIndex(ctype);
                ts ~= new DebugTypeNested(name, ct);
                break;
            default:
                assert(0, "Unknown CV4 Field Type: 0x" ~ to!string(fdtype, 16));
            }
            auto fix = f.peek!ubyte();
            if (fix > 0xF0)
                f.seek(f.tell() + (fix & 0xF));
        }
        t = new DebugTypeList(ts);
        break;

    case LF_MFUNCTION:
        debugfln("\tLF_MFUNCTION");
        auto rvtype = f.read!ushort();
        auto classt = f.read!ushort();
        auto thist = f.read!ushort();
        auto cc = f.read!ubyte();
        f.read!ubyte();
        auto parms = f.read!ushort();
        auto arglist = f.read!ushort();
        auto thisadjust = f.read!uint();
        debugfln("\t\tReturn type: %s", decodeCVType(rvtype));
        debugfln("\t\tClass type: %s", decodeCVType(classt));
        debugfln("\t\tThis type: %s", decodeCVType(thist));
        debugfln("\t\tCalling convention: %d", cc);
        debugfln("\t\tParams: %d", parms);
        debugfln("\t\tArgs: %s", decodeCVType(arglist));
        debugfln("\t\tThis adjust: 0x%.8X", thisadjust);
        auto rt = new DebugTypeIndex(rvtype);
        auto ct = new DebugTypeIndex(classt);
        auto tt = new DebugTypeIndex(thist);
        auto at = new DebugTypeIndex(arglist);
        assert(thisadjust == 0);
        t = new DebugTypeFunction(rt, at, ct, tt);
        break;

    case LF_MLIST:
        debugfln("\tLF_MLIST");
        auto start = f.tell();
        uint[] offsets;
        DebugType[] types;
        while (f.tell() < start + length - 2)
        {
            auto attr = f.read!ushort();
            auto ftype = f.read!ushort();
            auto mprop = (attr >> 2) & 0x7;
            uint offset;
            if (mprop == 4)
                offset = f.read!uint();
            debugfln("\t\tAttr: %s", decodeAttrib(attr));
            debugfln("\t\tType: %s", decodeCVType(ftype));
            debugfln("\t\tOffset: 0x%.8X", offset);
            offsets ~= offsets;
        }
        t = new DebugTypeMemberList(types, offsets);
        break;

    case LF_VTSHAPE:
        debugfln("\tLF_VTSHAPE");
        auto count = f.read!ushort();
        auto raw = f.readBytes((count+1)/2);
        auto flags = new ubyte[](count);
        foreach(i, ref v; flags)
            v = (i & 1) ? (raw[i/2] >> 4) : (raw[i/2] & 0xF);
        debugfln("\t\tCount: %d", count);
        debugfln("\t\tFlags: %(0x%.1X %)", flags);
        t = new DebugTypeVTBLShape(flags);
        break;

    case LF_ENUM:
        debugfln("\tLF_ENUM");
        auto count = f.read!ushort();
        auto btype = f.read!ushort();
        auto mlist = f.read!ushort();
        auto prop = f.read!ushort();
        auto name = f.readPreString();
        debugfln("\t\tName: %s", cast(string)name);
        debugfln("\t\tBase type: %s", decodeCVType(btype));
        debugfln("\t\tCount: %d", count);
        debugfln("\t\tMembers: %s", decodeCVType(mlist));
        debugfln("\t\tProperties: 0x%.4X", prop);
        auto bt = new DebugTypeIndex(btype);
        auto mt = new DebugTypeIndex(mlist);
        t = new DebugTypeEnum(name, bt, mt, prop);
        break;

    default:
        debugfln("Unknown CV4 Leaf Type: 0x%.8X", type);
        assert(0);
    }
    return t;
}

DebugValue readNumericLeaf(DataFile f)
{
    auto v = f.read!ushort();
    if (v < LF_NUMERIC)
    {
        return new DebugValueInt(v);
    }
    switch(v)
    {
    case LF_CHAR: return new DebugValueInt(f.read!byte());
    case LF_SHORT: return new DebugValueInt(f.read!short());
    case LF_USHORT: return new DebugValueInt(f.read!ushort());
    case LF_LONG: return new DebugValueInt(f.read!int());
    case LF_ULONG: return new DebugValueInt(f.read!uint());
    case LF_QUADWORD: return new DebugValueInt(f.read!long());
    case LF_UQUADWORD: return new DebugValueInt(f.read!ulong());
    default: assert(0);
    }
}

version(none)
{

void dumpSymbol(ref File of, DataFile f)
{
    auto len = f.read!ushort();
    auto symtype = f.read!ushort();
    switch (symtype)
    {
    case S_PUB32:
        of.writeln("Symbol: S_PUB32");
        auto offset = f.read!uint();
        auto segment = f.read!ushort();
        auto type = f.read!ushort();
        auto name = f.readPreString();
        of.writefln("Seg %.4X + 0x%.8X: %s (%d)", segment, offset, cast(string)name, type);
        break;
    case S_ALIGN:
        of.writeln("Symbol: S_ALIGN");
        f.seek(f.tell() + len - 2);
        break;
    case S_PROCREF:
        of.writeln("Symbol: S_PROCREF");
        auto checksum = f.read!uint();
        auto offset = f.read!uint();
        auto mod = f.read!ushort();
        of.writefln("\tChecksum: 0x%.8X", checksum);
        of.writefln("\tOffset: 0x%.8X", offset);
        of.writefln("\tModule: 0x%.4X", mod);
        break;
    case S_UDT:
        of.writeln("Symbol: S_UDT");
        auto type = f.read!ushort();
        auto name = f.readPreString();
        of.writefln("\tName: %s", cast(string)name);
        of.writefln("\tType: %s", decodeCVType(type));
        break;
    case S_SSEARCH:
        of.writeln("Symbol: S_SSEARCH");
        auto offset = f.read!uint();
        auto seg = f.read!ushort();
        of.writefln("\tOffset: 0x%.8X", offset);
        of.writefln("\tSegment: 0x%.4X", seg);
        break;
    case S_COMPILE:
        of.writeln("Symbol: S_COMPILE");
        auto flags = f.read!uint();
        auto machine = flags & 0xFF;
        flags >>= 8;
        auto verstr = f.readPreString();
        of.writefln("\tMachine: 0x%.2X", machine);
        of.writefln("\tFlags: 0x%.6X", flags);
        of.writefln("\tVersion: %s", cast(string)verstr);
        break;
    case S_GPROC32:
        of.writeln("Symbol: S_GPROC32");
        auto pParent = f.read!uint();
        auto pEnd = f.read!uint();
        auto pNext = f.read!uint();
        auto proclen = f.read!uint();
        auto debugstart = f.read!uint();
        auto debugend = f.read!uint();
        auto offset = f.read!uint();
        auto segment = f.read!ushort();
        auto proctype = f.read!ushort();
        auto flags = f.read!ubyte();
        auto name = f.readPreString();
        of.writefln("\tParent scope: 0x%.8X", pParent);
        of.writefln("\tEnd of scope: 0x%.8X", pEnd);
        of.writefln("\tNext scope: 0x%.8X", pNext);
        of.writefln("\tLength: 0x%.8X", proclen);
        of.writefln("\tDebug Star: 0x%.8X", debugstart);
        of.writefln("\tDebug End: 0x%.8X", debugend);
        of.writefln("\tOffset: 0x%.8X", offset);
        of.writefln("\tSegment: 0x%.4X", segment);
        of.writefln("\tType: %s", decodeCVType(proctype));
        of.writefln("\tFlags: 0x%.2X", flags);
        of.writefln("\tName: %s", cast(string)name);
        break;
    case S_BPREL32:
        of.writeln("Symbol: S_BPREL32");
        auto offset = f.read!uint();
        auto type = f.read!ushort();
        auto name = f.readPreString();
        of.writefln("\tName: %s", cast(string)name);
        of.writefln("\tType: %s", decodeCVType(type));
        of.writefln("\tOffset: 0x%.8X", offset);
        break;
    case S_RETURN:
        of.writeln("Symbol: S_RETURN");
        auto flags = f.read!ushort();
        auto style = f.read!ubyte();
        switch(style)
        {
        case 0x00:
            of.writefln("\tvoid return");
            break;
        case 0x01:
            of.writefln("\treg return");
            auto cReg = f.read!ubyte();
            foreach(i; 0..cReg)
                of.writefln("\tReg: 0x%.2X", f.read!ubyte());
            break;
        default:
            break;
        }
        break;
    case S_END:
        of.writeln("Symbol: S_END");
        break;
    case S_LDATA32:
        of.writeln("Symbol: S_LDATA32");
        auto offset = f.read!uint();
        auto segment = f.read!ushort();
        auto type = f.read!ushort();
        auto name = f.readPreString();
        of.writefln("\tName: %s", cast(string)name);
        of.writefln("\tType: %s", decodeCVType(type));
        of.writefln("\tSegment: 0x%.4X", segment);
        of.writefln("\tOffset: 0x%.8X", offset);
        break;
    case S_ENDARG:
        of.writeln("Symbol: S_ENDARG");
        break;
    case S_GDATA32:
        of.writeln("Symbol: S_GDATA32");
        auto offset = f.read!uint();
        auto segment = f.read!ushort();
        auto type = f.read!ushort();
        auto name = f.readPreString();
        of.writefln("\tName: %s", cast(string)name);
        of.writefln("\tType: %s", decodeCVType(type));
        of.writefln("\tSegment: 0x%.4X", segment);
        of.writefln("\tOffset: 0x%.8X", offset);
        break;

    case S_REGISTER:
        of.writeln("Symbol: S_REGISTER");
        assert(0);
    case S_CONSTANT:
        of.writeln("Symbol: S_CONSTANT");
        assert(0);
    case S_SKIP:
        of.writeln("Symbol: S_SKIP");
        assert(0);
    case S_CVRESERVE:
        of.writeln("Symbol: S_CVRESERVE");
        assert(0);
    case S_OBJNAME:
        of.writeln("Symbol: S_OBJNAME");
        assert(0);
    case S_COBOLUDT:
        of.writeln("Symbol: S_COBOLUDT");
        assert(0);
    case S_MANYREG:
        of.writeln("Symbol: S_MANYREG");
        assert(0);
    case S_ENTRYTHIS:
        of.writeln("Symbol: S_ENTRYTHIS");
        assert(0);

    case S_LPROC32:
        of.writeln("Symbol: S_LPROC32");
        assert(0);
    case S_THUNK32:
        of.writeln("Symbol: S_THUNK32");
        assert(0);
    case S_BLOCK32:
        of.writeln("Symbol: S_BLOCK32");
        assert(0);
    case S_VFTPATH32:
        of.writeln("Symbol: S_VFTPATH32");
        assert(0);
    case S_REGREL32:
        of.writeln("Symbol: S_REGREL32");
        assert(0);
    case S_LTHREAD32:
        of.writeln("Symbol: S_LTHREAD32");
        assert(0);
    case S_GTHREAD32:
        of.writeln("Symbol: S_GTHREAD32");
        assert(0);

    case S_DATAREF:
        of.writeln("Symbol: S_DATAREF");
        assert(0);

    case S_BPREL16:
    case S_LDATA16:
    case S_GDATA16:
    case S_PUB16:
    case S_LPROC16:
    case S_GPROC16:
    case S_THUNK16:
    case S_BLOCK16:
    case S_WITH16:
    case S_LABEL16:
    case S_CEXMODEL16:
    case S_VFTPATH16:
    case S_REGREL16:
    case S_LPROCMIPS:
    case S_GPROCMIPS:
        assert(0, "Unsupported Symbol type: 0x" ~ to!string(symtype, 16));
        break;
    default:
        assert(0, "Unknown Symbol type: 0x" ~ to!string(symtype, 16));
        break;
    }
}

}

string decodeAttrib(ushort attr)
{
    string r;
    switch(attr & 3)
    {
    case 0: r = ""; break;
    case 1: r = "private"; break;
    case 2: r = "protected"; break;
    case 3: r = "public"; break;
    default: assert(0);
    }
    if (r.length && ((attr >> 2) & 7)) r ~= " ";
    switch((attr >> 2) & 7)
    {
    case 0: break;
    case 1: r ~= "virtual"; break;
    case 2: r ~= "static"; break;
    case 3: r ~= "friend"; break;
    case 4: r ~= "virtual-i"; break;
    case 5: r ~= "virtual-p"; break;
    case 6: r ~= "virtual-ip"; break;
    default: assert(0);
    }
    if ((attr >> 5) & 1) r ~= " abstract-func";
    if ((attr >> 6) & 1) r ~= " final";
    if ((attr >> 7) & 1) r ~= " abstract-class";
    return r;
}

string decodeCVType(ushort typeind)
{
    if ((typeind & 0xF000) != 0)
        return format("0x%.4X", typeind);

    auto mode = (typeind >> 8) & 0x7;
    auto type = (typeind >> 4) & 0xF;
    auto size = typeind & 0x7;

    assert(mode == 0 || mode == 2 || mode == 4, "Unknown CV4 type mode: 0x" ~ to!string(mode, 16));
    auto pointer = (mode != 0) ? " *" : "";
    switch (type)
    {
    case 0x00:
        switch (size)
        {
        case 0x00: return "No type";
        case 0x03: return "void" ~ pointer;
        default: assert(0);
        }
    case 0x01:
        switch (size)
        {
        case 0x00: return "byte" ~ pointer;
        case 0x01: return "short" ~ pointer;
        case 0x02: return "c_long" ~ pointer;
        case 0x03: return "long" ~ pointer;
        default: assert(0);
        }
    case 0x02:
        switch (size)
        {
        case 0x00: return "ubyte" ~ pointer;
        case 0x01: return "ushort" ~ pointer;
        case 0x02: return "c_ulong" ~ pointer;
        case 0x03: return "ulong" ~ pointer;
        default: assert(0);
        }
    case 0x03:
        switch (size)
        {
        case 0x00: return "bool" ~ pointer;
        default: assert(0);
        }
    case 0x04:
        switch (size)
        {
        case 0x00: return "float" ~ pointer;
        case 0x01: return "double" ~ pointer;
        case 0x02: return "real" ~ pointer;
        default: assert(0);
        }
    case 0x05:
        switch (size)
        {
        case 0x00: return "cfloat" ~ pointer;
        case 0x01: return "cdouble" ~ pointer;
        case 0x02: return "creal" ~ pointer;
        default: assert(0);
        }
    case 0x06:
        assert(0);
    case 0x07:
        switch (size)
        {
        case 0x00: return "char" ~ pointer;
        case 0x01: return "wchar" ~ pointer;
        case 0x04: return "int" ~ pointer;
        case 0x05: return "uint" ~ pointer;
        default: assert(0);
        }
    default:
        assert(0, "Unknown CV4 type: 0x" ~ to!string(type, 16));
    }
}
