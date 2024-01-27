import std.stdio;

void main()
{
    File file = File("24.txt", "wb");
    for (uint i = 1; i <= 500; ++i)
        file.writefln("24-%04u", i);
}