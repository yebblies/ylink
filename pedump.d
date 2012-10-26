
import std.array;
import std.stdio;
import std.conv;
import std.string;
import std.file;
import std.path;

import coffdef;
import datafile;
import codeview;

void main(string[] args)
{
    assert(args.length == 2 || args.length == 4 && args[2] == "-of");
    auto of = args.length == 4 ? File(args[3], "w") : stdout;
    auto f = new DataFile(args[1].defaultExtension("exe"));

    auto dosMagic = f.readWordLE();
    assert(dosMagic == 0x5A4D);
    of.writeln("Dos Header found");
    f.seek(0x3C);
    auto peoffset = f.readWordLE();
    of.writefln("Coff Header at 0x%.4X", peoffset);

    f.seek(peoffset);
    auto pesig = f.readBytes(4);
    assert(pesig == PE_Signature);
    of.writeln("Coff Signature found");

    auto header = f.read!CoffHeader();

    of.write("Machine: ");
    switch (header.Machine)
    {
    case IMAGE_FILE_MACHINE_I386:
        of.writeln("I386");
        break;
    default:
        of.writeln("Unknown");
        assert(0);
    }

    of.writeln("NumberOfSections: ", header.NumberOfSections);
    of.writeln("TimeDateStamp: ", header.TimeDateStamp);
    of.writeln("PointerToSymbolTable: ", header.PointerToSymbolTable);
    of.writeln("NumberOfSymbols: ", header.NumberOfSymbols);
    of.writeln("SizeOfOptionalHeader: ", header.SizeOfOptionalHeader);
    of.writeln("Characteristics:");
    if (header.Characteristics & IMAGE_FILE_RELOCS_STRIPPED)         of.writeln("\tRelocs stripped");
    if (header.Characteristics & IMAGE_FILE_EXECUTABLE_IMAGE)        of.writeln("\tExecutable");
    if (header.Characteristics & IMAGE_FILE_LINE_NUMS_STRIPPED)      of.writeln("\tLine nums stripped");
    if (header.Characteristics & IMAGE_FILE_LOCAL_SYMS_STRIPPED)     of.writeln("\tLocal syms stripped");
    if (header.Characteristics & IMAGE_FILE_AGGRESSIVE_WS_TRIM)      of.writeln("\tAggressive working set trim");
    if (header.Characteristics & IMAGE_FILE_LARGE_ADDRESS_AWARE)     of.writeln("\tLarge address aware");
    if (header.Characteristics & IMAGE_FILE_BYTES_REVERSED_LO)       of.writeln("\tBytes reversed lo");
    if (header.Characteristics & IMAGE_FILE_32BIT_MACHINE)           of.writeln("\t32-bit");
    if (header.Characteristics & IMAGE_FILE_DEBUG_STRIPPED)          of.writeln("\tDebug stripped");
    if (header.Characteristics & IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP) of.writeln("\tRemovable run from swap");
    if (header.Characteristics & IMAGE_FILE_NET_RUN_FROM_SWAP)       of.writeln("\tNetwork run from swap");
    if (header.Characteristics & IMAGE_FILE_SYSTEM)                  of.writeln("\tSystem file");
    if (header.Characteristics & IMAGE_FILE_DLL)                     of.writeln("\tDll");
    if (header.Characteristics & IMAGE_FILE_UP_SYSTEM_ONLY)          of.writeln("\tUniprocessor only");
    if (header.Characteristics & IMAGE_FILE_BYTES_REVERSED_HI)       of.writeln("\tBytes reversed hi");

    of.writeln();

    auto opthead = f.read!OptionalHeader();
    assert(opthead.Magic == PE_MAGIC);
    of.writeln("Coff Optional Header found");
    of.writefln("Linker version: %d.%d", opthead.MajorLinkerVersion, opthead.MinorLinkerVersion);
    of.writefln("Size of code:  0x%.8X", opthead.SizeOfCode);
    of.writefln("Size of data:  0x%.8X", opthead.SizeOfInitializedData);
    of.writefln("Size of bss:   0x%.8X", opthead.SizeOfUninitializedData);
    of.writefln("Entry point:   0x%.8X", opthead.ImageBase + opthead.AddressOfEntryPoint);
    of.writefln("Base of code:  0x%.8X", opthead.ImageBase + opthead.BaseOfCode);
    of.writefln("Base of data:  0x%.8X", opthead.ImageBase + opthead.BaseOfData);
    of.writefln("Image base:    0x%.8X", opthead.ImageBase);
    of.writefln("Alignment:     0x%.8X", opthead.SectionAlignment);
    of.writefln("FileAlignment: 0x%.8X", opthead.FileAlignment);
    of.writefln("OS version:        %d.%d", opthead.MajorOperatingSystemVersion, opthead.MinorOperatingSystemVersion);
    of.writefln("Image version:     %d.%d", opthead.MajorImageVersion, opthead.MinorImageVersion);
    of.writefln("Subsystem version: %d.%d", opthead.MajorSubsystemVersion, opthead.MinorSubsystemVersion);
    of.writefln("Win32 Version:     %d", opthead.Win32VersionValue);
    of.writefln("Size of image: 0x%.8X", opthead.SizeOfImage);
    of.writefln("Size of headers: 0x%.8X", opthead.SizeOfHeaders);
    of.writefln("CheckSum: 0x%.8X", opthead.CheckSum);
    switch(opthead.Subsystem)
    {
    case IMAGE_SUBSYSTEM_WINDOWS_CUI:
        of.writeln("Subsystem type: CUI");
        break;
    case IMAGE_SUBSYSTEM_WINDOWS_GUI:
        of.writeln("Subsystem type: GUI");
        break;
    default:
        of.writeln("Subsystem type: Unknown");
        assert(0);
    }
    of.writefln("DllCharacteristics: 0x%.4X", opthead.DllCharacteristics);
    of.writefln("Size of stack reserve: 0x%.8X", opthead.SizeOfStackReserve);
    of.writefln("Size of stack commit:  0x%.8X", opthead.SizeOfStackCommit);
    of.writefln("Size of heap reserve:  0x%.8X", opthead.SizeOfHeapReserve);
    of.writefln("Size of heap commit:   0x%.8X", opthead.SizeOfHeapCommit);
    of.writefln("Loader flags:          0x%.8X", opthead.LoaderFlags);
    of.writefln("Number of directories: 0x%.8X", opthead.NumberOfRvaAndSizes);

    of.writeln();

    assert(opthead.NumberOfRvaAndSizes == 0x10);

    auto ddnames = ["ExportTable", "ImportTable", "ResourceTable", "ExceptionTable", "CertificateTable", "BaseRelocationTable", "Debug", "Architecture", "GlobalPtr", "TLSTable", "LoadConfigTable", "BoundImportTable", "ImportAddressTable", "DelayImportDescriptor", "CLRRuntimeHeader", "Reserved"];

    auto dds = f.read!DataDirectories();
    foreach(i, dd; dds.tupleof)
    {
        if (dd.VirtualAddress)
        {
            of.writeln("Data directory: ", ddnames[i]);
            of.writefln("\tVirtual address: 0x%.8X", dd.VirtualAddress);
            of.writefln("\tSize:            0x%.8X", dd.Size);
        }
    }

    of.writeln();

    auto secheadoffset = f.tell();

    auto secheads = new SectionHeader[](header.NumberOfSections);

    foreach(ref sechead; secheads)
    {
        sechead = f.read!SectionHeader();
        auto name = sechead.Name[];
        while (name.back == '\0')
            name.popBack();
        of.writeln("Section: ", name);
        of.writefln("\tVirtual Size:    0x%.8X", sechead.VirtualSize);
        of.writefln("\tVirtual Address: 0x%.8X", sechead.VirtualAddress);
        of.writefln("\tFile Size:       0x%.8X", sechead.SizeOfRawData);
        of.writefln("\tFile Address:    0x%.8X", sechead.PointerToRawData);
        of.writefln("\tRelocations:     0x%.8X (%d)", sechead.PointerToRelocations, sechead.NumberOfRelocations);
        of.writefln("\tLine numbers:    0x%.8X (%d)", sechead.PointerToLinenumbers, sechead.NumberOfLinenumbers);
        of.writefln("\tCharacteristics:");
        if (sechead.Characteristics & IMAGE_SCN_TYPE_NO_PAD)            of.writeln("\t\tNo padding");
        if (sechead.Characteristics & IMAGE_SCN_CNT_CODE)               of.writeln("\t\tCode");
        if (sechead.Characteristics & IMAGE_SCN_CNT_INITIALIZED_DATA)   of.writeln("\t\tData");
        if (sechead.Characteristics & IMAGE_SCN_CNT_UNINITIALIZED_DATA) of.writeln("\t\tBSS");
        if (sechead.Characteristics & IMAGE_SCN_LNK_OTHER)              of.writeln("\t\tLink - Other");
        if (sechead.Characteristics & IMAGE_SCN_LNK_INFO)               of.writeln("\t\tLink - Info");
        if (sechead.Characteristics & IMAGE_SCN_LNK_REMOVE)             of.writeln("\t\tLink - Remove");
        if (sechead.Characteristics & IMAGE_SCN_LNK_COMDAT)             of.writeln("\t\tLink - Comdat");
        if (sechead.Characteristics & IMAGE_SCN_GPREL)                  of.writeln("\t\tGPREL");
        if (sechead.Characteristics & IMAGE_SCN_MEM_PURGEABLE)          of.writeln("\t\tMemory - Purgeable");
        if (sechead.Characteristics & IMAGE_SCN_MEM_LOCKED)             of.writeln("\t\tMemory - Locked");
        if (sechead.Characteristics & IMAGE_SCN_MEM_PRELOAD)            of.writeln("\t\tMemory - Preload");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_1BYTES)           of.writeln("\t\tAlign - 1");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_2BYTES)           of.writeln("\t\tAlign - 2");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_4BYTES)           of.writeln("\t\tAlign - 4");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_8BYTES)           of.writeln("\t\tAlign - 8");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_16BYTES)          of.writeln("\t\tAlign - 16");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_32BYTES)          of.writeln("\t\tAlign - 32");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_64BYTES)          of.writeln("\t\tAlign - 64");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_128BYTES)         of.writeln("\t\tAlign - 128");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_256BYTES)         of.writeln("\t\tAlign - 256");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_512BYTES)         of.writeln("\t\tAlign - 512");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_1024BYTES)        of.writeln("\t\tAlign - 1024");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_2048BYTES)        of.writeln("\t\tAlign - 2048");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_4096BYTES)        of.writeln("\t\tAlign - 4096");
        if (sechead.Characteristics & IMAGE_SCN_ALIGN_8192BYTES)        of.writeln("\t\tAlign - 8192");
        if (sechead.Characteristics & IMAGE_SCN_LNK_NRELOC_OVFL)        of.writeln("\t\tLink - Reloc overflow");
        if (sechead.Characteristics & IMAGE_SCN_MEM_DISCARDABLE)        of.writeln("\t\tMemory - Discardable");
        if (sechead.Characteristics & IMAGE_SCN_MEM_NOT_CACHED)         of.writeln("\t\tMemory - Not cached");
        if (sechead.Characteristics & IMAGE_SCN_MEM_NOT_PAGED)          of.writeln("\t\tMemory - Not paged");
        if (sechead.Characteristics & IMAGE_SCN_MEM_SHARED)             of.writeln("\t\tMemory - Shared");
        if (sechead.Characteristics & IMAGE_SCN_MEM_EXECUTE)            of.writeln("\t\tMemory - Execute");
        if (sechead.Characteristics & IMAGE_SCN_MEM_READ)               of.writeln("\t\tMemory - Read");
        if (sechead.Characteristics & IMAGE_SCN_MEM_WRITE)              of.writeln("\t\tMemory - Write");
    }

    of.writeln();

    if (dds.Debug.VirtualAddress && dds.Debug.Size)
    {
        of.writeln("Has a debug directory");
        SectionHeader debughead;
        foreach(ref sechead; secheads)
            if (sechead.VirtualAddress == dds.Debug.VirtualAddress)
                debughead = sechead;
        assert(debughead.VirtualAddress == dds.Debug.VirtualAddress);
        f.seek(debughead.PointerToRawData);

        auto dd = f.read!DebugDirectory();
        assert(dd.Characteristics == 0);
        assert(dd.Type == IMAGE_DEBUG_TYPE_CODEVIEW);
        assert(dd.MajorVersion == 0);
        assert(dd.MinorVersion == 0);
        of.writefln("Debug info type: Codeview %d.%d", dd.MajorVersion, dd.MinorVersion);
        of.writefln("Virtual address: 0x%.8X", dd.AddressOfRawData);
        of.writefln("File address:    0x%.8X", dd.PointerToRawData);
        of.writefln("Data size:       0x%.8X", dd.SizeOfData);

        if (dd.SizeOfData == 0)
        {
            of.writeln("Debug section empty");
        }
        else
        {
            of.writeln();
            dumpCodeview(of, f, dd.PointerToRawData);
        }
    }
}

void dumpCodeview(ref File of, DataFile f, uint lfaBase)
{
    f.seek(lfaBase);
    auto cvh = f.read!uint();
    assert(cvh == CV41_SIG, "Only CV41 is supported");
    of.writefln("Found CV41 debug information");
    auto lfoDir = f.read!uint();

    f.seek(lfaBase + lfoDir);
    auto dirheader = f.read!CV_DIRHEADER();
    assert(dirheader.cbDirHeader == CV_DIRHEADER.sizeof);
    assert(dirheader.cbDirEntry == CV_DIRENTRY.sizeof);
    assert(dirheader.lfoNextDir == 0);
    assert(dirheader.flags == 0);
    of.writefln("Found %d subsections", dirheader.cDir);

    foreach(i; 0..dirheader.cDir)
    {
        f.seek(lfaBase + lfoDir + CV_DIRHEADER.sizeof + CV_DIRENTRY.sizeof * i);
        auto entry = f.read!CV_DIRENTRY();
        of.writefln("Entry: 0x%.4X 0x%.4X 0x%.8X 0x%.8X", entry.subsection, entry.iMod, lfaBase + entry.lfo, entry.cb);
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
            of.writefln("CV sstModule: %s", cast(string)name);
            if (iLib)
                of.writefln("\tFrom lib #%d", iLib);
            break;
        case sstSrcModule:
            of.writeln("CV sstSrcModule");

            // Module header
            auto cFile = f.read!ushort();
            auto cSeg = f.read!ushort();
            of.writefln("\t%d files", cFile);
            of.writefln("\t%d segments", cSeg);
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

            // File Info
            foreach(j, fileoff; filebase)
            {
                of.writefln("File %d at 0x%.8X", j, fileoff);
                f.seek(lfaBase + entry.lfo + fileoff);
                auto xcSeg = f.read!ushort();
                assert(f.read!ushort() == 0);
                auto baseSrcLn = cast(immutable uint[])f.readBytes(uint.sizeof * xcSeg);
                auto startend = cast(immutable uint[2][])f.readBytes((uint[2]).sizeof * xcSeg);
                auto name = f.readPreString();
                of.writeln("\tName: ", cast(string)name);
                of.writefln("\tLine maps: %(0x%.8X, %)", baseSrcLn);
                of.writefln("\tSegs: %(%(0x%.8X..%), %)", startend);

                foreach(k, off; baseSrcLn)
                {
                    f.seek(lfaBase + entry.lfo + off);
                    of.writefln("\tLine numbers in segment %d:", k);
                    auto Segi = f.read!ushort();
                    auto cPair = f.read!ushort();
                    auto offset = cast(uint[])f.readBytes(uint.sizeof*cPair);
                    auto linenum = cast(ushort[])f.readBytes(ushort.sizeof*cPair);
                    foreach(l; 0..cPair)
                        of.writefln("\t\t0x%.8X: %d", offset[l], linenum[l]);
                }
            }

            foreach(j; 0..cSeg)
            {
                of.writefln("Seg %d (%d) at 0x%.8X..0x%.8X", j, segindex[j], segstart[j], segend[j]);
            }
            break;
        case sstLibraries:
            of.writeln("CV Library list:");
            auto len = f.read!ubyte();
            assert(len == 0);
            auto count = 1;
            while ((len = f.read!ubyte()) != 0)
            {
                of.writefln("\tLib #%d: %s", count, cast(string)f.readBytes(len));
                count++;
            }
            break;
        case sstGlobalPub: // List of all public symbols
            auto symhash = f.read!ushort();
            auto addrhash = f.read!ushort();
            of.writefln("CV Global Public Symbols:");
            //of.writefln("\tSymbol hash: 0x%.4X", symhash);
            //of.writefln("\tAddress hash: 0x%.4X", addrhash);
            auto cbSymbol = f.read!uint();
            auto cbSymHash = f.read!uint();
            auto cbAddrHash = f.read!uint();
            //of.writefln("\tSymbols: 0x%X bytes", cbSymbol);
            //of.writefln("\tcbSymHash: 0x%X bytes", cbSymHash);
            //of.writefln("\tcbAddrHash: 0x%X bytes", cbAddrHash);
            auto symstart = f.tell();
            while(f.tell() < symstart + cbSymbol)
            {
                f.alignto(4);
                dumpSymbol(of, f);
            }
            assert(f.tell() == symstart + cbSymbol);
            break;
        case sstGlobalSym: // List of all non-public symbols
            of.writefln("CV Global Symbols:");
            auto symhash = f.read!ushort();
            auto addrhash = f.read!ushort();
            auto cbSymbol = f.read!uint();
            auto cbSymHash = f.read!uint();
            auto cbAddrHash = f.read!uint();
            auto symstart = f.tell();
            while(f.tell() < symstart + cbSymbol)
            {
                f.alignto(4);
                dumpSymbol(of, f);
            }
            assert(f.tell() == symstart + cbSymbol);
            break;
        case sstGlobalTypes:
            of.writefln("CV Global Types:");
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
                dumpType(of, f);
            }
            break;
        case sstFileIndex:
            of.writefln("CV File Index:");
            of.writefln("%.8X", f.tell());
            auto cMod = f.read!ushort();
            auto cRef = f.read!ushort();
            auto ModStart = cast(ushort[])f.readBytes(ushort.sizeof * cMod);
            auto cRefCnt = cast(ushort[])f.readBytes(ushort.sizeof * cMod);
            auto NameRef = cast(uint[])f.readBytes(uint.sizeof * cRef);
            auto nametable = f.tell();
            foreach(j; 0..cMod)
            {
                of.writefln("\tModule %d:", j+1);
                auto p = ModStart[j];
                foreach(k; 0..cRefCnt[j])
                {
                    f.seek(nametable + NameRef[p + k]);
                    auto name = f.readPreString();
                    of.writefln("\t\tSourcefile: %s", cast(string)name);
                }
            }
            break;
        case sstSegMap:
            of.writefln("CV Segment Map:");
            auto cSeg = f.read!ushort();
            auto cSegLog = f.read!ushort();
            auto SegDesc = new CV_SEGDESC[](cSegLog);
            of.writefln("\tcSeg: %d", cSeg);
            of.writefln("\tcSegLog: %d", cSegLog);
            foreach(j, ref v; SegDesc)
                v = f.read!CV_SEGDESC();
            foreach(j, ref v; SegDesc)
            {
                of.writefln("\tSegment %d:", j+1);
                of.writefln("\t\tFlags: 0x%.4X", v.flags);
                of.writefln("\t\tOverlay: %d", v.ovl);
                of.writefln("\t\tGroup: %d", v.group);
                of.writefln("\t\tFrame: %d", v.frame);
                of.writefln("\t\tSeg name: 0x%.4X", v.iSegName);
                of.writefln("\t\tClass name: 0x%.4X", v.iClassName);
                of.writefln("\t\tOffset: 0x%.8X", v.offset);
                of.writefln("\t\tLength: 0x%.8X", v.cbseg);
            }
            break;
        case sstSegName:
            of.writefln("CV Segment Names:");
            auto count = 0;
            while (f.tell() < lfaBase + entry.lfo + entry.cb)
            {
                count++;
                auto name = f.readZString();
                of.writefln("\tSegment %d: %s", count, cast(string)name);
            }
            break;
        case sstAlignSym:
            of.writefln("CV Aligned Symbols:");
            auto sig = f.read!uint();
            assert(sig == 0x00000001);
            while(f.tell() < lfaBase + entry.lfo + entry.cb)
            {
                f.alignto(4);
                dumpSymbol(of, f);
            }
            break;
        default:
            writefln("Unhandled CV subsection type 0x%.3X", entry.subsection);
            assert(0);
        }
    }
}

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
    case S_ENDARG:
        of.writeln("Symbol: S_ENDARG");
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

    case S_LDATA32:
        of.writeln("Symbol: S_LDATA32");
        assert(0);
    case S_GDATA32:
        of.writeln("Symbol: S_GDATA32");
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

void dumpType(ref File of, DataFile f)
{
    auto len = f.read!ushort();
    of.writeln("Type:");
    auto start = f.tell();
    while (f.tell() < start + len)
    {
        dumpTypeLeaf(of, f);
    }
}

void dumpTypeLeaf(ref File of, DataFile f)
{
    auto type = f.read!ushort();
    switch (type)
    {
    case LF_ARGLIST:
        of.writeln("\tLF_ARGLIST");
        auto count = f.read!ushort();
        of.writefln("\t\t%d args", count);
        foreach(i; 0..count)
        {
            auto typind = f.read!ushort();
            of.writefln("\t\t%s", decodeCVType(typind));
        }
        break;

    case LF_PROCEDURE:
        of.writeln("\tLF_PROCEDURE");
        auto rettype = f.read!ushort();
        auto cc = f.read!ubyte();
        auto reserved = f.read!ubyte();
        auto argcount = f.read!ushort();
        auto arglist = f.read!ushort();
        of.writefln("\t\tReturn type: %s", decodeCVType(rettype));
        of.writefln("\t\tCalling convention: %d", cc);
        of.writefln("\t\tArg count: %d", argcount);
        of.writefln("\t\tArg list: %s", decodeCVType(arglist));
        break;

    case LF_FIELDLIST:
        of.writeln("\tLF_FIELDLIST");
        while (dumpFieldLeaf(of, f)) {}
        break;

    case LF_STRUCTURE:
        of.writeln("\tLF_STRUCT");
        auto count = f.read!ushort();
        auto ftype = f.read!ushort();
        auto prop = f.read!ushort();
        auto dlist = f.read!ushort();
        auto vtbl = f.read!ushort();
        auto length = f.read!ushort();
        auto name = f.readPreString();
        of.writefln("\t\tName: %s", cast(string)name);
        of.writefln("\t\tMembers: %d", count);
        of.writefln("\t\tFields: %s", decodeCVType(ftype));
        of.writefln("\t\tProperties: %.4X", prop);
        of.writefln("\t\tDerived: %s", decodeCVType(dlist));
        of.writefln("\t\tVtbl: %s", decodeCVType(vtbl));
        of.writefln("\t\tsizeof: %d", length);
        break;

    case LF_POINTER:
        of.writeln("\tLF_POINTER");
        auto attr = f.read!ushort();
        auto ptype = f.read!ushort();
        of.writefln("\t\ttype: %s", decodeCVType(ptype));
        of.writefln("\t\tattr: %.4X", attr);
        assert(attr == 0x0A);
        break;

    case LF_MODIFIER:
    case LF_ARRAY:
    case LF_CLASS:
    case LF_UNION:
    case LF_ENUM:
    case LF_MFUNCTION:
    case LF_VTSHAPE:
    case LF_COBOL0:
    case LF_COBOL1:
    case LF_BARRAY:
    case LF_LABEL:
    case LF_NULL:
    case LF_NOTTRAN:
    case LF_DIMARRAY:
    case LF_VFTPATH:
    case LF_PRECOMP:
    case LF_ENDPRECOMP:
    case LF_OEM:

    case LF_SKIP:
    case LF_DEFARG:
    case LF_LIST:
    case LF_DERIVED:
    case LF_BITFIELD:
    case LF_METHODLIST:
    case LF_DIMCONU:
    case LF_DIMCONLU:
    case LF_DIMVARU:
    case LF_DIMVARLU:
    case LF_REFSYM:

    case LF_BCLASS:
    case LF_VBCLASS:
    case LF_IVBCLASS:
    case LF_ENUMERATE:
    case LF_FRIENDFCN:
    case LF_INDEX:
    case LF_MEMBER:
    case LF_STMEMBER:
    case LF_METHOD:
    case LF_NESTTYPE:
    case LF_VFUNCTAB:
    case LF_FRIENDCLS:
    case LF_ONEMETHOD:
    case LF_VFUNCOFF:

    case LF_CHAR:
    case LF_SHORT:
    case LF_USHORT:
    case LF_LONG:
    case LF_ULONG:
    case LF_REAL32:
    case LF_REAL64:
    case LF_REAL80:
    case LF_REAL128:
    case LF_QUADWORD:
    case LF_UQUADWORD:
    case LF_REAL48:
    case LF_COMPLEX32:
    case LF_COMPLEX64:
    case LF_COMPLEX80:
    case LF_COMPLEX128:
    case LF_VARSTRING:

    case LF_PAD0:
    case LF_PAD1:
    case LF_PAD2:
    case LF_PAD3:
    case LF_PAD4:
    case LF_PAD5:
    case LF_PAD6:
    case LF_PAD7:
    case LF_PAD8:
    case LF_PAD9:
    case LF_PAD10:
    case LF_PAD11:
    case LF_PAD12:
    case LF_PAD13:
    case LF_PAD14:
    case LF_PAD15:
        assert(0, "Unsupported CV4 Type: 0x" ~ to!string(type, 16));
    default:
        assert(0, "Unknown CV4 Type: 0x" ~ to!string(type, 16));
    }
}

bool dumpFieldLeaf(ref File of, DataFile f)
{
    auto type = f.read!ushort();
    switch (type)
    {
    case LF_MEMBER:
        auto ftype = f.read!ushort();
        auto attrib = decodeAttrib(f.read!ushort());
        auto offset = f.read!ushort();
        auto name = f.readPreString();
        of.writefln("\t\tMember: %s (+%s) (%s)", cast(string)name, offset, attrib);
        break;
    case LF_NOTTRAN:
        return false;
    default:
        assert(0, "Unknown CV4 Field Type: 0x" ~ to!string(type, 16));
    }
    auto fix = f.peek!ubyte();
    if (fix > 0xF0)
        f.seek(f.tell() + (fix & 0xF));
    return true;
}

string decodeAttrib(ushort attrib)
{
    return "<<attrib>>";
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
