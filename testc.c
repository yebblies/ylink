
#include <stdio.h>

struct S
{
    signed char sc;
    unsigned char uc;
    signed short ss;
    unsigned short us;
    signed int si;
    unsigned int ui;
    signed long sl;
    unsigned long ul;
    signed long long sll;
    unsigned long long ull;
    float f;
    double d;
    long double ild;
    _Imaginary float imf;
    _Imaginary double imd;
    _Imaginary long double imld;
    _Complex float cf;
    _Complex double cd;
    _Complex long double cld;
};

void func(signed char sc, unsigned char uc, signed short ss, unsigned short us, signed int si, unsigned int ui, signed long sl, unsigned long ul, signed long long sll, unsigned long long ull)
{
}

void ffunc(float f, double d, long double ld) {}
void cfunc(_Complex float f, _Complex double d, _Complex long double ld) {}
int ifunc(_Imaginary float f, _Imaginary double d, _Imaginary long double ld) {}
//struct S sfunc(struct S s) { return s; }

int main(int argc, char *argv)
{
    printf("Hello\n");
    printf("Hello %d\n", 137);
    return 0;
}
