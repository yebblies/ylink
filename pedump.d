
import std.array;
import std.stdio;
import std.conv;
import std.string;
import std.file;
import std.path;

import coffdef;
import datafile;

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

    assert(opthead.NumberOfRvaAndSizes == 0x10);

    auto ddnames = ["ExportTable", "ImportTable", "ResourceTable", "ExceptionTable", "CertificateTable", "BaseRelocationTable", "Debug", "Architecture", "GlobalPtr", "TLSTable", "LoadConfigTable", "BoundImportTable", "ImportAddressTable", "DelayImportDescriptor", "CLRRuntimeHeader", "Reserved"];

    auto dds = f.read!DataDirectories();
    foreach(i, dd; dds.tupleof)
    {
        if (dd.VirtualAddress)
        {
            of.writeln("Data directory: ", ddnames[i]);
            of.writefln("\tVirtual address: 0x%.8X", dd.VirtualAddress);
            of.writefln("\tSize:             0x%.8X", dd.Size);
        }
    }

    foreach(i; 0..header.NumberOfSections)
    {
        auto sechead = f.read!SectionHeader();
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
}
