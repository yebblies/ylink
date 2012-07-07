
import std.exception;
import std.file;
import std.path;
import std.process;
import std.range;
import std.stdio;

enum SegmentType
{
    Text,
    Data,
    BSS,
    Const,
    TLS,
    Debug,
    Import,
    Export,
    Reloc,
}

class Segment
{
    SegmentType type;
}
