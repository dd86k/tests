module test;

import std.stdio;
import std.json;

void main()
{
    JSONValue j;
    
    // Associative array
    j["puter"] = ["iscool":true];
    
    // Build array manually
    struct F { char[20] f; size_t fl; char[20] v; size_t vl; }
    struct S { size_t c; F[5] f; }
    static immutable S[] data = [
        {
            2,
            [
            { "field", 5, "value", 5 },
            { "say",   3, "what!", 5 },
            ]
        },
        {
            3,
            [
            { "ext",    3, "1100", 4 },
            { "name",   4, "John", 4 },
            { "secret", 6, "iloveD2001", 10 },
            ]
        },
    ];
    string[string][] list = new string[string][data.length];
    size_t i;
    foreach (item; data) // foreach items
    {
        foreach (ref row; item.f[0..item.c])
        {
            string f = row.f[0..row.fl].idup;
            string v = row.v[0..row.vl].idup;
            list[i][f] = v;
        }
        ++i;
    }
    j["list"] = list;
    
    writeln(j);
}