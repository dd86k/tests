import std.stdio;

void main() {
	for (int i; i < 64; ++i)
		printf("%3d. %.*f\n", i, i, 0.3);
}