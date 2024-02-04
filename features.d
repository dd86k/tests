module features;

import std.stdio;
import std.format;

string fversion(int version_)
{
    return format("%d.%03d", version_ / 1000, version_ % 1000);
}

void supported(int minversion, string feature)
{
    if (__VERSION__ < minversion) return;
    writeln(fversion(minversion), ": ", feature);
}

void main()
{
    writeln("Compiler: ", __VENDOR__, " v", fversion(__VERSION__));
    writeln("Compiler features:");
    supported(2_068, "64-bit bswap");
    supported(2_083, "getTargetInfo trait");
    supported(2_092, "printf/scanf pragma");
    supported(2_096, "noreturn bottom type");
    supported(2_100, "core.int128 type");
    supported(2_100, "@mustuse attribute");
    supported(2_101, "classInstanceAlignment trait");
}