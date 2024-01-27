import std;

void main()
{
    float a = 1./0.;
    float b = 0./0.;
    writeln("1./0.=", a);
    writeln("0./0.=", b);
    
    float fimin32 = cast(float)int.max;
    float fumin32 = cast(float)uint.max;
    double dimin64 = cast(double)long.max;
    double dumin64 = cast(double)ulong.max;
    writeln("int.max fit in float   : ", int.max == fimin32);
    writeln("uint.max fit in float  : ", uint.max == fumin32);
    writeln("long.max fit in double : ", long.max == dimin64);
    writeln("ulong.max fit in double: ", ulong.max == dumin64);
    writeln("int.max fit in float   : ", int.max == cast(int)fimin32);
    writeln("uint.max fit in float  : ", uint.max == cast(uint)fumin32);
    writeln("long.max fit in double : ", long.max == cast(long)dimin64);
    writeln("ulong.max fit in double: ", ulong.max == cast(ulong)dumin64);
}