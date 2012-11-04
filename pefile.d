
import std.array;
import std.conv;
import std.stdio;

import coffdef;
import datafile;
import debuginfo;
import executablefile;
import loadcv;

final class PEFile : ExecutableFile
{
private:
    DataFile f;

    DataDirectories dds;
    SectionHeader[] secheads;

public:
    this(DataFile f)
    {
        super(f.filename);
        this.f = f;
    }
    void processFile(bool dodump)()
    {
        void debugfln(T...)(T args)
        {
            static if (dodump)
            {
                static if (T.length)
                    writefln(args);
                else
                    writeln();
            }
        }
        f.seek(0);
        auto dosMagic = f.readWordLE();
        assert(dosMagic == 0x5A4D);
        debugfln("Dos Header found");
        f.seek(0x3C);
        auto peoffset = f.readWordLE();
        debugfln("Coff Header at 0x%.4X", peoffset);

        f.seek(peoffset);
        auto pesig = f.readBytes(4);
        assert(pesig == PE_Signature);
        debugfln("Coff Signature found");

        auto header = f.read!CoffHeader();

        switch (header.Machine)
        {
        case IMAGE_FILE_MACHINE_I386:
            debugfln("Machine: I386");
            break;
        default:
            debugfln("Machine: Unknown");
            assert(0, "Unsupported machine type");
        }

        debugfln("NumberOfSections: ", header.NumberOfSections);
        debugfln("TimeDateStamp: ", header.TimeDateStamp);
        debugfln("PointerToSymbolTable: ", header.PointerToSymbolTable);
        debugfln("NumberOfSymbols: ", header.NumberOfSymbols);
        debugfln("SizeOfOptionalHeader: ", header.SizeOfOptionalHeader);
        debugfln("Characteristics:");
        if (header.Characteristics & IMAGE_FILE_RELOCS_STRIPPED)         debugfln("\tRelocs stripped");
        if (header.Characteristics & IMAGE_FILE_EXECUTABLE_IMAGE)        debugfln("\tExecutable");
        if (header.Characteristics & IMAGE_FILE_LINE_NUMS_STRIPPED)      debugfln("\tLine nums stripped");
        if (header.Characteristics & IMAGE_FILE_LOCAL_SYMS_STRIPPED)     debugfln("\tLocal syms stripped");
        if (header.Characteristics & IMAGE_FILE_AGGRESSIVE_WS_TRIM)      debugfln("\tAggressive working set trim");
        if (header.Characteristics & IMAGE_FILE_LARGE_ADDRESS_AWARE)     debugfln("\tLarge address aware");
        if (header.Characteristics & IMAGE_FILE_BYTES_REVERSED_LO)       debugfln("\tBytes reversed lo");
        if (header.Characteristics & IMAGE_FILE_32BIT_MACHINE)           debugfln("\t32-bit");
        if (header.Characteristics & IMAGE_FILE_DEBUG_STRIPPED)          debugfln("\tDebug stripped");
        if (header.Characteristics & IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP) debugfln("\tRemovable run from swap");
        if (header.Characteristics & IMAGE_FILE_NET_RUN_FROM_SWAP)       debugfln("\tNetwork run from swap");
        if (header.Characteristics & IMAGE_FILE_SYSTEM)                  debugfln("\tSystem file");
        if (header.Characteristics & IMAGE_FILE_DLL)                     debugfln("\tDll");
        if (header.Characteristics & IMAGE_FILE_UP_SYSTEM_ONLY)          debugfln("\tUniprocessor only");
        if (header.Characteristics & IMAGE_FILE_BYTES_REVERSED_HI)       debugfln("\tBytes reversed hi");
        debugfln();

        auto opthead = f.read!OptionalHeader();
        assert(opthead.Magic == PE_MAGIC);
        debugfln("Coff Optional Header found");
        debugfln("Linker version: %d.%d", opthead.MajorLinkerVersion, opthead.MinorLinkerVersion);
        debugfln("Size of code:  0x%.8X", opthead.SizeOfCode);
        debugfln("Size of data:  0x%.8X", opthead.SizeOfInitializedData);
        debugfln("Size of bss:   0x%.8X", opthead.SizeOfUninitializedData);
        debugfln("Entry point:   0x%.8X", opthead.ImageBase + opthead.AddressOfEntryPoint);
        debugfln("Base of code:  0x%.8X", opthead.ImageBase + opthead.BaseOfCode);
        debugfln("Base of data:  0x%.8X", opthead.ImageBase + opthead.BaseOfData);
        debugfln("Image base:    0x%.8X", opthead.ImageBase);
        debugfln("Alignment:     0x%.8X", opthead.SectionAlignment);
        debugfln("FileAlignment: 0x%.8X", opthead.FileAlignment);
        debugfln("OS version:        %d.%d", opthead.MajorOperatingSystemVersion, opthead.MinorOperatingSystemVersion);
        debugfln("Image version:     %d.%d", opthead.MajorImageVersion, opthead.MinorImageVersion);
        debugfln("Subsystem version: %d.%d", opthead.MajorSubsystemVersion, opthead.MinorSubsystemVersion);
        debugfln("Win32 Version:     %d", opthead.Win32VersionValue);
        debugfln("Size of image: 0x%.8X", opthead.SizeOfImage);
        debugfln("Size of headers: 0x%.8X", opthead.SizeOfHeaders);
        debugfln("CheckSum: 0x%.8X", opthead.CheckSum);

        switch(opthead.Subsystem)
        {
        case IMAGE_SUBSYSTEM_WINDOWS_CUI:
            debugfln("Subsystem type: CUI");
            break;
        case IMAGE_SUBSYSTEM_WINDOWS_GUI:
            debugfln("Subsystem type: GUI");
            break;
        default:
            debugfln("Subsystem type: Unknown");
            assert(0, "Unsupported subsystem");
        }
        debugfln("DllCharacteristics: 0x%.4X", opthead.DllCharacteristics);
        debugfln("Size of stack reserve: 0x%.8X", opthead.SizeOfStackReserve);
        debugfln("Size of stack commit:  0x%.8X", opthead.SizeOfStackCommit);
        debugfln("Size of heap reserve:  0x%.8X", opthead.SizeOfHeapReserve);
        debugfln("Size of heap commit:   0x%.8X", opthead.SizeOfHeapCommit);
        debugfln("Loader flags:          0x%.8X", opthead.LoaderFlags);
        debugfln("Number of directories: 0x%.8X", opthead.NumberOfRvaAndSizes);
        debugfln();

        assert(opthead.NumberOfRvaAndSizes == 0x10);

        auto ddnames = ["ExportTable", "ImportTable", "ResourceTable", "ExceptionTable", "CertificateTable", "BaseRelocationTable", "Debug", "Architecture", "GlobalPtr", "TLSTable", "LoadConfigTable", "BoundImportTable", "ImportAddressTable", "DelayImportDescriptor", "CLRRuntimeHeader", "Reserved"];

        dds = f.read!DataDirectories();
        foreach(i, dd; dds.tupleof)
        {
            if (dd.VirtualAddress)
            {
                debugfln("Data directory: %s", ddnames[i]);
                debugfln("\tVirtual address: 0x%.8X", dd.VirtualAddress);
                debugfln("\tSize:            0x%.8X", dd.Size);
            }
        }
        debugfln();

        auto secheadoffset = f.tell();
        secheads = new SectionHeader[](header.NumberOfSections);

        foreach(ref sechead; secheads)
        {
            sechead = f.read!SectionHeader();
            auto name = sechead.Name[];
            while (name.back == '\0')
                name.popBack();
            debugfln("Section: ", name);
            debugfln("\tVirtual Size:    0x%.8X", sechead.VirtualSize);
            debugfln("\tVirtual Address: 0x%.8X", sechead.VirtualAddress);
            debugfln("\tFile Size:       0x%.8X", sechead.SizeOfRawData);
            debugfln("\tFile Address:    0x%.8X", sechead.PointerToRawData);
            debugfln("\tRelocations:     0x%.8X (%d)", sechead.PointerToRelocations, sechead.NumberOfRelocations);
            debugfln("\tLine numbers:    0x%.8X (%d)", sechead.PointerToLinenumbers, sechead.NumberOfLinenumbers);
            debugfln("\tCharacteristics:");
            if (sechead.Characteristics & IMAGE_SCN_TYPE_NO_PAD)            debugfln("\t\tNo padding");
            if (sechead.Characteristics & IMAGE_SCN_CNT_CODE)               debugfln("\t\tCode");
            if (sechead.Characteristics & IMAGE_SCN_CNT_INITIALIZED_DATA)   debugfln("\t\tData");
            if (sechead.Characteristics & IMAGE_SCN_CNT_UNINITIALIZED_DATA) debugfln("\t\tBSS");
            if (sechead.Characteristics & IMAGE_SCN_LNK_OTHER)              debugfln("\t\tLink - Other");
            if (sechead.Characteristics & IMAGE_SCN_LNK_INFO)               debugfln("\t\tLink - Info");
            if (sechead.Characteristics & IMAGE_SCN_LNK_REMOVE)             debugfln("\t\tLink - Remove");
            if (sechead.Characteristics & IMAGE_SCN_LNK_COMDAT)             debugfln("\t\tLink - Comdat");
            if (sechead.Characteristics & IMAGE_SCN_GPREL)                  debugfln("\t\tGPREL");
            if (sechead.Characteristics & IMAGE_SCN_MEM_PURGEABLE)          debugfln("\t\tMemory - Purgeable");
            if (sechead.Characteristics & IMAGE_SCN_MEM_LOCKED)             debugfln("\t\tMemory - Locked");
            if (sechead.Characteristics & IMAGE_SCN_MEM_PRELOAD)            debugfln("\t\tMemory - Preload");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_1BYTES)           debugfln("\t\tAlign - 1");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_2BYTES)           debugfln("\t\tAlign - 2");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_4BYTES)           debugfln("\t\tAlign - 4");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_8BYTES)           debugfln("\t\tAlign - 8");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_16BYTES)          debugfln("\t\tAlign - 16");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_32BYTES)          debugfln("\t\tAlign - 32");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_64BYTES)          debugfln("\t\tAlign - 64");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_128BYTES)         debugfln("\t\tAlign - 128");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_256BYTES)         debugfln("\t\tAlign - 256");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_512BYTES)         debugfln("\t\tAlign - 512");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_1024BYTES)        debugfln("\t\tAlign - 1024");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_2048BYTES)        debugfln("\t\tAlign - 2048");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_4096BYTES)        debugfln("\t\tAlign - 4096");
            if (sechead.Characteristics & IMAGE_SCN_ALIGN_8192BYTES)        debugfln("\t\tAlign - 8192");
            if (sechead.Characteristics & IMAGE_SCN_LNK_NRELOC_OVFL)        debugfln("\t\tLink - Reloc overflow");
            if (sechead.Characteristics & IMAGE_SCN_MEM_DISCARDABLE)        debugfln("\t\tMemory - Discardable");
            if (sechead.Characteristics & IMAGE_SCN_MEM_NOT_CACHED)         debugfln("\t\tMemory - Not cached");
            if (sechead.Characteristics & IMAGE_SCN_MEM_NOT_PAGED)          debugfln("\t\tMemory - Not paged");
            if (sechead.Characteristics & IMAGE_SCN_MEM_SHARED)             debugfln("\t\tMemory - Shared");
            if (sechead.Characteristics & IMAGE_SCN_MEM_EXECUTE)            debugfln("\t\tMemory - Execute");
            if (sechead.Characteristics & IMAGE_SCN_MEM_READ)               debugfln("\t\tMemory - Read");
            if (sechead.Characteristics & IMAGE_SCN_MEM_WRITE)              debugfln("\t\tMemory - Write");
        }
        debugfln();
    }
    override void dump()
    {
        processFile!true();
    }
    override void loadData()
    {
        processFile!false();
    }
    override void loadDebugInfo(DebugInfo di)
    {
        void debugfln(T...)(T args)
        {
            debug(LOADPE)
            {
                static if (T.length)
                    writefln(args);
                else
                    writeln();
            }
        }
        if (dds.Debug.VirtualAddress && dds.Debug.Size)
        {
            debugfln("Has a debug directory");
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
            debugfln("Debug info type: Codeview %d.%d", dd.MajorVersion, dd.MinorVersion);
            debugfln("Virtual address: 0x%.8X", dd.AddressOfRawData);
            debugfln("File address:    0x%.8X", dd.PointerToRawData);
            debugfln("Data size:       0x%.8X", dd.SizeOfData);
            if (dd.SizeOfData)
            {
                debugfln("Debug section contains data");
                loadCodeView(f, dd.PointerToRawData, di);
            }
        }
    }
}
