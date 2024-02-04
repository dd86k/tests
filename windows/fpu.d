import std.stdio;
import core.stdc.math : sqrt;
import core.sys.windows.windows;

private:

// MSVC only
extern (C) uint _controlfp(uint,uint);
extern (C) uint _clearfp();

enum _MCW_DN	= 0x03000000;
enum _DN_SAVE	= 0x00000000;
enum _DN_FLUSH	= 0x01000000;

enum _MCW_EM	= 0x0008001F;
enum _EM_INVALID	= 0x00000010;
enum _EM_DENORMAL	= 0x00080000;
enum _EM_ZERODIVIDE	= 0x00000008;
enum _EM_OVERFLOW	= 0x00000004;
enum _EM_UNDERFLOW	= 0x00000002;
enum _EM_INEXACT	= 0x00000001;

enum _EM_ALL	=
	_EM_INVALID | _EM_DENORMAL | _EM_ZERODIVIDE |
	_EM_OVERFLOW | _EM_UNDERFLOW | _EM_INEXACT;

union F {
	float f32;
	uint u32;
}

extern (Windows)
int handler(EXCEPTION_POINTERS *e) {
	printf("exception: %x\n", e.ExceptionRecord.ExceptionCode);
	return 0;
}

void main() {
	F n = void;
	
	n.u32 = 0xff800000;
	printf("0xff800000	%f\n", n.f32);
	
	n.u32 = 0xffc00000;
	printf("0xffc00000	%f\n", n.f32);
	
	n.f32 = sqrt(n.f32);
	printf("sqrt(n.f32)	%f\n", n.f32);
	
	SetUnhandledExceptionFilter(&handler);
	n.f32 = sqrt(n.f32);
	printf("with handler	%f\n", n.f32);
	
	_controlfp(_controlfp(0, 0) & ~(_EM_INVALID | _EM_ZERODIVIDE | _EM_OVERFLOW), _MCW_EM);
	n.f32 = sqrt(n.f32);
	printf("_controlfp	%f\n", n.f32);
}