module aa;

import std.stdio;

void main(string[] args)
{
    string[int] aa;
    
    aa[50] = "test";
    aa[86] = "bird";
    aa[22] = null; // null can be included
    
    foreach (key, val; aa)
    {
        writeln("key: ", key, ", value: ", val ? val : "(null)");
    }
}