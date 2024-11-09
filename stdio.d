module stdio;

import std.stdio;

void main(string[] args)
{
Lread:
    write("input: ");
    stdout.flush();
    string line = readln();
    writefln("output: %(%02x,%)", cast(immutable(ubyte)[])line);
    goto Lread;
}