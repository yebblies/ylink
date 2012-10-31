
import std.algorithm;
import std.conv;
import std.exception;
import std.stdio;

import section;
import segment;

final class SectionTable
{
    CombinedSection[][][SectionClass.max+1] sections;
    immutable(ubyte)[][][SectionClass.max+1] secNames;

    CombinedSection add(Section sec)
    {
        int nameIndex = -1;
        foreach(i, name; secNames[sec.secclass])
        {
            if (name == sec.name)
            {
                nameIndex = i;
                break;
            }
        }
        if (nameIndex == -1)
        {
            nameIndex = secNames[sec.secclass].length;
            secNames[sec.secclass] ~= sec.name;
            sections[sec.secclass].length++;
        }
        CombinedSection sx;
        foreach(s; sections[sec.secclass][nameIndex])
        {
            if (s.tag == sec.tag)
            {
                sx = s;
                break;
            }
        }
        if (!sx)
        {
            sx = new CombinedSection(sec.name, sec.tag, sec.secclass);
            sections[sec.secclass][nameIndex] ~= sx;
        }
        //enforce(sec.secclass == s.secclass, "Section " ~ cast(string)sec.name ~ " is in multiple classes");
        sx.append(sec);
        return sx;
    }
    void dump()
    {
        writeln("Section Table:");
        foreach(secclass, nameGroup; sections)
        {
            writeln(cast(SectionClass)secclass, " sections");
            foreach(secs; nameGroup)
            {
                foreach(s; secs)
                    s.dump();
            }
        }
    }
    private void segAppend(Segment seg, CombinedSection[][] nameGroup)
    {
        foreach(secs; nameGroup)
        {
            sort!("a.tag < b.tag", SwapStrategy.stable)(secs);
            foreach(sec; secs)
                seg.append(sec);
        }
    }
    Segment[SegmentType] allocateSegments(uint baseAddress, uint segAlign, uint fileAlign)
    {
        //Import,Export,Text,TLS,Data,Const,BSS,Reloc,Debug,
        Segment[SegmentType] segs;
        auto offset = baseAddress + 0x1000;
        auto fileOffset = 0x400;

        auto Import = new Segment(SegmentType.Import, offset, fileOffset);
        segAppend(Import, sections[SectionClass.IData]);
        Import.length = (Import.length + fileAlign - 1) & ~(fileAlign - 1);
        offset = (offset + Import.length + segAlign - 1) & ~(segAlign - 1);
        fileOffset += Import.length;

        auto Export = new Segment(SegmentType.Export, offset, fileOffset);
        segAppend(Export, sections[SectionClass.EData]);
        offset = (offset + Export.length + segAlign - 1) & ~(segAlign - 1);
        fileOffset = (fileOffset + Import.length + fileAlign - 1) & ~(fileAlign - 1);

        auto Text = new Segment(SegmentType.Text, offset, fileOffset);
        segAppend(Text, sections[SectionClass.Code]);
        Text.length = (Text.length + fileAlign - 1) & ~(fileAlign - 1);
        offset = (offset + Text.length + segAlign - 1) & ~(segAlign - 1);
        fileOffset += Text.length;

        auto TLS = new Segment(SegmentType.TLS, offset, fileOffset);
        segAppend(TLS, sections[SectionClass.TLS]);
        TLS.length = (TLS.length + fileAlign - 1) & ~(fileAlign - 1);
        offset = (offset + TLS.length + segAlign - 1) & ~(segAlign - 1);
        fileOffset += TLS.length;

        auto Data = new Segment(SegmentType.Data, offset, fileOffset);
        segAppend(Data, sections[SectionClass.Data]);
        Data.length = (Data.length + fileAlign - 1) & ~(fileAlign - 1);
        offset = (offset + Data.length + segAlign - 1) & ~(segAlign - 1);
        fileOffset += Data.length;

        auto Const = new Segment(SegmentType.Const, offset, fileOffset);
        segAppend(Const, sections[SectionClass.Const]);
        Const.length = (Const.length + fileAlign - 1) & ~(fileAlign - 1);
        offset = (offset + Const.length + segAlign - 1) & ~(segAlign - 1);
        fileOffset += Const.length;

        auto BSS = new Segment(SegmentType.BSS, offset, 0);
        segAppend(BSS, sections[SectionClass.BSS]);
        offset = (offset + BSS.length + segAlign - 1) & ~(segAlign - 1);

        Import.allocate(segAlign);
        Export.allocate(segAlign);
        Text.allocate(segAlign);
        TLS.allocate(segAlign);
        Data.allocate(segAlign);
        Const.allocate(segAlign);

        size_t segid = 0;
        if (Import.length) Import.segid = segid++;
        if (Export.length) Export.segid = segid++;
        if (Text.length) Text.segid = segid++;
        if (TLS.length) TLS.segid = segid++;
        if (Data.length) Data.segid = segid++;
        if (Const.length) Const.segid = segid++;
        if (BSS.length) BSS.segid = segid++;

        if (Import.length) segs[SegmentType.Import] = Import;
        if (Export.length) segs[SegmentType.Export] = Export;
        if (Text.length) segs[SegmentType.Text] = Text;
        if (TLS.length) segs[SegmentType.TLS] = TLS;
        if (Data.length) segs[SegmentType.Data] = Data;
        if (Const.length) segs[SegmentType.Const] = Const;
        if (BSS.length) segs[SegmentType.BSS] = BSS;
        return segs;
    }
}
