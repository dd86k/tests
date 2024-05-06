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
    writeln("- ", fversion(minversion), ": ", feature);
}

struct Feature { int minversion; string name; }
immutable Feature[] features = [
    { 2_068, "64-bit bswap" },
    { 2_083, "getTargetInfo trait" },
    { 2_092, "printf/scanf pragma" },
    { 2_096, "noreturn bottom type" },
    { 2_100, "core.int128 type" },
    { 2_100, "@mustuse attribute" },
    { 2_101, "classInstanceAlignment trait" },
    { 2_105, "std.system.ISA" },
    { 2_106, "std.traits.Unshared" },
    { 2_107, "core.stdc.stdatomic" },
];

void main()
{
    writeln("Compiler: ", __VENDOR__, " v", fversion(__VERSION__));
    writeln("Features:");
    foreach (ref feature; features)
        with (feature) supported(minversion, name);
}