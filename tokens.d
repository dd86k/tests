module tokens;

import std.stdio;

void main()
{
    // Special tokens
    writeln("__DATE__\t: ", __DATE__);
    writeln("__TIME__\t: ", __TIME__);
    writeln("__TIMESTAMP__\t: ", __TIMESTAMP__);
    writeln("__VENDOR__\t: ", __VENDOR__);
    writeln("__VERSION__\t: ", __VERSION__);
    
    // Special keywords
    writeln("__FILE_FULL_PATH__\t: ", __FILE_FULL_PATH__);
    writeln("__FILE__\t: ", __FILE__);
    writeln("__LINE__\t: ", __LINE__);
    writeln("__MODULE__\t: ", __MODULE__);
    writeln("__FUNCTION__\t: ", __FUNCTION__);
    writeln("__PRETTY_FUNCTION__\t: ", __PRETTY_FUNCTION__);
}