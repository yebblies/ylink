
import std.stdio;
import std.regex;

void main(string[] args)
{
    assert(args.length == 3);
    auto inf = File(args[1], "r");
    auto outf = File(args[2], "w");
    auto r = ctRegex!(r"^ \p{Hex_Digit}{4}:\p{Hex_Digit}{8} {7}([^\s]+)\s+(\p{Hex_Digit}{8})$");
    auto r2 = ctRegex!(r"^ \p{Hex_Digit}{4}:\p{Hex_Digit}{8}  Imp  ([^\s]+)\s+(\p{Hex_Digit}{8})$");
    foreach(l; inf.byLine())
    {
        try
        {
            auto m = match(l, r);
            if (!m.empty)
            {
                auto c = m.captures;
                outf.writeln(c[2], '\t', c[1]);
            }
        }
        catch {}
        try
        {
            auto m = match(l, r2);
            if (!m.empty)
            {
                auto c = m.captures;
                outf.writeln(c[2], '\t', c[1]);
            }
        }
        catch {}
    }
}
