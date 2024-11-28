import std.stdio;
import std.conv : text;

immutable int padding = 12;

void printval(T)(string name, T val, string fmt)
{
    writefln("%*s(%%"~fmt~"): %"~fmt, padding, name, val);
}
void print(T)(string altname = null)
{
    writeln;
    if (altname)
        writeln(altname, " (", T.stringof, ")");
    else
        writeln(T.stringof);
    
    // Character types
    static if (is(T == char) || is(T == wchar) || is(T == dchar))
    {
        printval!T("init", T.init, "d");
        printval!T("min", T.min, "d");
        printval!T("max", T.max, "d");
    }
    // Float types
    else static if (is(T == float) || is(T == double) || is(T == real))
    {
        printval!T("init", T.init, "s");
        printval!T("max", T.max, "s");
        printval!T("dig", T.dig, "s");
        printval!T("mant_dig", T.mant_dig, "s");
        printval!T("epsilon", T.epsilon, "s");
        printval!T("min_normal", T.min_normal, "s");
    }
    // Integer types (last due to int promotion)
    else static if (is(T == byte) || is(T == ubyte) ||
        is(T == short) || is(T == ushort) ||
        is(T == int) || is(T == uint) ||
        is(T == long) || is(T == ulong))
    {
        printval!T("init", T.init, "s");
        printval!T("min", T.min, "s");
        printval!T("max", T.max, "s");
        printval!T("min", T.min, "u");
        printval!T("max", T.max, "u");
        printval!T("min", T.min, "d");
        printval!T("max", T.max, "d");
        printval!T("min", T.min, "x");
        printval!T("max", T.max, "x");
        printval!T("min", T.min, "o");
        printval!T("max", T.max, "o");
    }
    else
        static assert(false, text("Unfit type: ", T.stringof));
}

void main()
{
    // Integrals
    print!byte;
    print!ubyte;
    print!short;
    print!ushort;
    print!int;
    print!uint;
    print!long;
    print!ulong;
    print!size_t("size_t");
    print!ptrdiff_t("ptrdiff_t");
    // Characters
    print!char;
    print!wchar;
    print!dchar;
    // Floats
    print!float;
    print!double;
    print!real; // NOTE: `real` depends on the compiler and target
}