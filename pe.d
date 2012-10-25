
import std.conv;
import std.stdio;
import std.string;

import coffdef;
import linker;
import segment;
import symboltable;

void buildPE(string filename, Segment[SegmentType] segments, SymbolTable symtab)
{
    writeln("Building exe file ", filename);

    auto f = new File(filename, "wb");
    f.rawWrite(DosHeader);
    f.rawWrite(PE_Signature);

    CoffHeader ch;
    with(ch)
    {
        Machine = IMAGE_FILE_MACHINE_I386;
        assert(segments.length <= 0xFFFF);
        NumberOfSections = cast(ushort)segments.length;
        TimeDateStamp = 0x00000000;
        PointerToSymbolTable = 0x00000000;
        NumberOfSymbols = 0x00000000;
        SizeOfOptionalHeader = OptionalHeader.sizeof + DataDirectories.sizeof;
        Characteristics |= IMAGE_FILE_RELOCS_STRIPPED;
        Characteristics |= IMAGE_FILE_EXECUTABLE_IMAGE;
        Characteristics |= IMAGE_FILE_LINE_NUMS_STRIPPED;
        Characteristics |= IMAGE_FILE_LOCAL_SYMS_STRIPPED;
        Characteristics |= IMAGE_FILE_BYTES_REVERSED_LO;
        Characteristics |= IMAGE_FILE_32BIT_MACHINE;
        Characteristics |= IMAGE_FILE_DEBUG_STRIPPED;
        Characteristics |= IMAGE_FILE_BYTES_REVERSED_HI;
    }
    f.rawWrite((&ch)[0..1]);

    OptionalHeader oh;
    with(oh)
    {
        Magic = PE_MAGIC;
        MajorLinkerVersion = majorVersion;
        MinorLinkerVersion = minorVersion;
        SizeOfCode = segments[SegmentType.Text].length;
        SizeOfInitializedData = segments[SegmentType.Data].length;
        SizeOfUninitializedData = segments[SegmentType.BSS].length;
        AddressOfEntryPoint = symtab.searchName(symtab.entryPoint).getAddress() - imageBase;
        BaseOfCode = segments[SegmentType.Text].base - imageBase;
        BaseOfData = segments[SegmentType.Data].base - imageBase;

        ImageBase = imageBase;
        SectionAlignment = segAlign;
        FileAlignment = fileAlign;
        MajorOperatingSystemVersion = 0x0001;
        MinorOperatingSystemVersion = 0x0000;
        MajorImageVersion = 0x0000;
        MinorImageVersion = 0x0000;
        MajorSubsystemVersion = 0x0003;
        MinorSubsystemVersion = 0x000A;
        Win32VersionValue = 0x00000000;
        SizeOfImage = 0x00000000;
        foreach(seg; segments)
            if (seg.base + seg.length - imageBase > SizeOfImage)
                SizeOfImage = (seg.base + seg.length + segAlign - 1) & ~(segAlign - 1) - imageBase;
        SizeOfHeaders = 0x400;
        CheckSum = 0x00000000;
        Subsystem = IMAGE_SUBSYSTEM_WINDOWS_CUI;
        DllCharacteristics = 0x0000;
        SizeOfStackReserve = 0x00100000;
        SizeOfStackCommit = 0x00001000;;
        SizeOfHeapReserve = 0x00100000;
        SizeOfHeapCommit = 0x00001000;
        LoaderFlags = 0x00000000;
        NumberOfRvaAndSizes = DataDirectories.sizeof / IMAGE_DATA_DIRECTORY.sizeof;
    }
    f.rawWrite((&oh)[0..1]);

    DataDirectories dd;
    with(dd)
    {
        ExportTable.VirtualAddress = 0x00000000;
        ExportTable.Size = 0x00000000;
        ImportTable.VirtualAddress = segments[SegmentType.Import].base - imageBase;
        ImportTable.Size = segments[SegmentType.Import].length;
        ResourceTable.VirtualAddress = 0x00000000;
        ResourceTable.Size = 0x00000000;
        BaseRelocationTable.VirtualAddress = 0x00000000;
        BaseRelocationTable.Size = 0x00000000;
        Debug.VirtualAddress = 0x00000000;
        Debug.Size = 0x00000000;

        auto tlsused = symtab.searchName(cast(immutable(ubyte)[])"__tls_used");
        if (tlsused)
        {
            auto tlstab = tlsused.getAddress() - imageBase;
            TLSTable.VirtualAddress = tlstab;
            TLSTable.Size = 24;
        }
        else
        {
            TLSTable.VirtualAddress = 0;
            TLSTable.Size = 0;
        }
    }
    f.rawWrite((&dd)[0..1]);

    with(SegmentType)
    foreach(segid; [Import, /*Export,*/ Text, TLS, Data, Const, BSS, /*Reloc, Debug*/])
    {
        if (segid in segments)
        {
            auto seg = segments[segid];
            writeln(segid, " ", seg.length);
            SectionHeader sh;
            sh.Name = SectionNames[segid];
            writeln(SectionNames[segid]);
            sh.VirtualSize = seg.length;
            sh.VirtualAddress = seg.base - imageBase;
            sh.SizeOfRawData = segid == BSS ? 0 : seg.length;
            writeln(seg.fileOffset);
            sh.PointerToRawData = seg.fileOffset;
            sh.PointerToRelocations = 0;
            sh.PointerToLinenumbers = 0;
            sh.NumberOfRelocations = 0;
            sh.NumberOfLinenumbers = 0;
            switch(segid)
            {
            case Import:
                sh.Characteristics = IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE;
                break;
            case Text:
                sh.Characteristics = IMAGE_SCN_CNT_CODE | IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_MEM_READ;
                break;
            case TLS:
                sh.Characteristics = IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE;
                break;
            case Data:
                sh.Characteristics = IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE;
                break;
            case Const:
                sh.Characteristics = IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ;
                break;
            case BSS:
                sh.Characteristics = IMAGE_SCN_CNT_UNINITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE;
                break;
            default:
                assert(0);
            }
            f.rawWrite((&sh)[0..1]);
        }
    }
    with(SegmentType)
    foreach(segid; [Import, /*Export,*/ Text, TLS, Data, Const, BSS, /*Reloc, Debug*/])
    {
        if (segid in segments)
        {
            auto seg = segments[segid];
            if (segid == BSS) continue;
            f.seek(seg.fileOffset);
            f.rawWrite(seg.data);
        }
    }
    f.close();
}
