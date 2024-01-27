module strings;

import std.stdio;
import std.string : fromStringz;
import core.stdc.stdio;

void print(string s1, const(char)[] s2, const(char)* s3)
{
    writefln("writefln: s1=%s s2=%s s3=%s", s1, s2, s3);
    writefln("writefln: s1=%s s2=%s s3=%s", s1, s2, s3.fromStringz);
    printf("printf: s3=%s\n", s3);
}

void main()
{
    print("I", "love", "pizza");
}