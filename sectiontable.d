
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
    Segment[SegmentType] allocateSegments(uint baseAddress, uint segAlign)
    {
        //Import,Export,Text,TLS,Data,Const,BSS,Reloc,Debug,
        Segment[SegmentType] segs;
        auto offset = baseAddress + 0x1000; // OPTLINK uses this address, I don't know why

        auto Import = new Segment(SegmentType.Import, offset);
        segAppend(Import, sections[SectionClass.IData]);
        offset = (offset + Import.length + segAlign - 1) & ~(segAlign - 1);

        //auto Export = new Segment(SegmentType.Export, offset);
        //segAppend(Export, sections[SectionClass.EData]);
        //offset = (offset + Export.length + segAlign - 1) & ~(segAlign - 1);

        auto Text = new Segment(SegmentType.Text, offset);
        segAppend(Text, sections[SectionClass.Code]);
        offset = (offset + Text.length + segAlign - 1) & ~(segAlign - 1);

        auto TLS = new Segment(SegmentType.TLS, offset);
        segAppend(TLS, sections[SectionClass.TLS]);
        offset = (offset + TLS.length + segAlign - 1) & ~(segAlign - 1);

        auto Data = new Segment(SegmentType.Data, offset);
        segAppend(Data, sections[SectionClass.Data]);
        offset = (offset + Data.length + segAlign - 1) & ~(segAlign - 1);

        auto Const = new Segment(SegmentType.Const, offset);
        segAppend(Const, sections[SectionClass.Const]);
        offset = (offset + Const.length + segAlign - 1) & ~(segAlign - 1);

        auto BSS = new Segment(SegmentType.BSS, offset);
        segAppend(BSS, sections[SectionClass.BSS]);
        segAppend(BSS, sections[SectionClass.ENDBSS]);
        offset = (offset + BSS.length + segAlign - 1) & ~(segAlign - 1);

        segs[SegmentType.Import] = Import;
        //segs[SegmentType.Export] = Export;
        segs[SegmentType.Text] = Text;
        segs[SegmentType.TLS] = TLS;
        segs[SegmentType.Data] = Data;
        segs[SegmentType.Const] = Const;
        segs[SegmentType.BSS] = BSS;
        return segs;
    }
}
