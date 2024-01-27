import std.stdio;

void main() {
	printf("%#llx\n", 0x2L);
	// NOTE: 16 is total length, including 0x
	printf("%#016llx\n", 0x2L);
	printf("0x%016llx\n", 0x2L);
	writefln("%#016x", 0x33L);
}