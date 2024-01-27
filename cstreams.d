import core.stdc.stdio;

__gshared FILE* stdout;

version (Windows) enum tty = "CONOUT$";
version (OSX)     enum tty = "/dev/stdout";
version (linux)   enum tty = "/dev/tty";
version (FreeBSD) enum tty = "/dev/stdout";
version (NetBSD)  enum tty = "/dev/stdout";
version (OpenBSD) enum tty = "/dev/stdout";

extern (C)
void main() {
	stdout = fopen(tty, "wb");
	fputs("test\n", stdout);
}
