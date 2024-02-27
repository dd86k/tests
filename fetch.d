/+ dub.sdl:
dependency "requests" version="~>2.1.3"
+/

// NOTE: Run this with dub fetch.d

import std.stdio;
import requests;

int main(string[] args)
{
    if (args.length < 2)
    {
        stderr.writeln("Give me an URL!");
        return 1;
    }
    auto content = getContent(args[1]);
    writeln(content);
    return 0;
}