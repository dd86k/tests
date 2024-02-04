module test;

import std.stdio;
import std.json;

void main()
{
    JSONValue jroot;
    
    JSONValue jputer = ["iscool":true];
    
    jroot["puter"] = jputer;
    
    writeln(jroot);
}