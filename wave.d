import std.stdio, core.thread, core.bitop;

void main()
{
    int i;
Lagain:
    writefln("%064b", ror(0xf00f_f00f_f00f_f00f, i++ % 32));
    Thread.sleep(dur!"msecs"(100));
    goto Lagain;
}