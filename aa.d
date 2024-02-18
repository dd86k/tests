module aa;

import std.stdio;

void main(string[] args)
{
    string[int] aa;
    
    aa[50]  = "test";
    aa[86] = "bird";
    
    foreach (key, val; aa)
    {
        writeln("key: ", key, ", value: ", val);
    }
}