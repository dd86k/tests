import core.stdc.stdio;

extern (C)
void main(int argc, const(char) **argv)
{
    // argc+1 to see if last argument is a null terminator
    foreach (i, const(char) *arg; argv[0..argc+1])
    {
        printf("argv[%d]=%p\n", cast(int)i, arg);
    }
}