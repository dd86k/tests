import std.stdio;

//TODO: Redo with array of TypeInfo (typeid(T))

immutable int padding = 10;

void printin(T)(string altname = null)
{
    writefln("%*s  init=%s\tmin=%s\tmax=%s",
        padding, altname ? altname : T.stringof,
        T.init, T.min, T.max);
}
void printch(T)()
{
    writefln("%*s  init=%u\tmin=%u\tmax=%u",
        padding, T.stringof,
        T.init, T.min, T.max);
}
void printfp(T)()
{
    writefln("%*s  dig=%s\tmant_dig=%s\tepsilon=%s\tmin_normal=%s\tmax=%s\tinit=%s",
        padding, T.stringof,
        T.dig, T.mant_dig, T.epsilon, T.min_normal, T.max, T.init);
}

void main()
{
    // Integrals
    printin!byte;
    printin!ubyte;
    printin!short;
    printin!ushort;
    printin!int;
    printin!uint;
    printin!long;
    printin!ulong;
    printin!size_t("size_t");
    printin!ptrdiff_t("ptrdiff_t");
    // Characters
    printch!char;
    printch!wchar;
    printch!dchar;
    // Floats
    printfp!float;
    printfp!double;
    printfp!real; // NOTE: Still uses x87 types
}