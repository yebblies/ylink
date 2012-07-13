
import std.conv;
import std.stdio;

import segment;
import symboltable;

private:

struct DosHeader
{
align(1):
    ushort     e_magic;
    ushort     e_cblp;
    ushort     e_cp;
    ushort     e_crlc;
    ushort     e_cparhdr;
    ushort     e_minalloc;
    ushort     e_maxalloc;
    ushort     e_ss;
    ushort     e_sp;
    ushort     e_csum;
    ushort     e_ip;
    ushort     e_cs;
    ushort     e_lfarlc;
    ushort     e_ovno;
    ushort[4]  e_res;
    ushort     e_oemid;
    ushort     e_oeminfo;
    ushort[10] e_res2;
    int        e_lfanew;
}
static assert(DosHeader.sizeof == 64);

public:

void buildPE(string filename, Segment[SegmentType] segments, SymbolTable symtab)
{
    writeln("Building exe file ", filename);
}
