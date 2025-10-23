module features;

import std.stdio;
import std.format;

string fversion(int version_)
{
    return format("%d.%03d", version_ / 1000, version_ % 1000);
}

void supported(int minversion, string feature)
{
    writeln(
        __VERSION__ >= minversion ? "++ " : "   ",
        fversion(minversion), ": ", feature);
}

struct Feature { int minversion; string name; }
immutable Feature[] features = [
    { 2_067, "GC options" },
    { 2_068, "core.bitop 64-bit bswap" },
    { 2_076, "-betterC enhancements" },
    { 2_079, "Eponymous std.exception.enforce, std.experimental.all" },
    { 2_083, "getTargetInfo trait" },
    { 2_086, "import std" },
    { 2_087, "multithread GC sweep" },
    { 2_092, "printf/scanf pragma" },
    { 2_096, "noreturn bottom type" },
    { 2_098, "Concurrent GC gcopt=fork (POSIX)" },
    { 2_100, "core.int128 type" },
    { 2_100, "@mustuse attribute" },
    { 2_101, "Bit fields, classInstanceAlignment trait" },
    { 2_105, "std.system.ISA, version(VisionOS)" },
    { 2_106, "std.traits.Unshared" },
    { 2_107, "core.stdc.stdatomic" },
    { 2_108, "Interpolated Expression Sequences, call-site __FILE__" },
    { 2_109, "Bitfield Introspection Capability, __ctfeWrite, core.sys.linux.sys.mount" },
    { 2_111, "__rvalue, DMD -oq, Placement New Expression" },
];

void main()
{
    writeln("Compiler: ", __VENDOR__, " v", fversion(__VERSION__));
    writeln("Features:");
    foreach (ref feature; features)
        with (feature) supported(minversion, name);
}