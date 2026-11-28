#include <stdio.h>

#define INCAP 131072
#define OUTCAP 131072

static char inbuf[INCAP];
static char outbuf[OUTCAP];
static int inlen = 0, inpos = 0, outlen = 0;

static int fill(void) {
    if (inpos >= inlen) {
        inlen = (int)fread(inbuf, 1, INCAP, stdin);
        inpos = 0;
        if (inlen <= 0) return 0;
    }
    return 1;
}

static long long nextll(void) {
    int c;
    do { if (!fill()) return 0; c = inbuf[inpos++]; } while (c < '0' || c > '9');
    long long v = 0;
    while (c >= '0' && c <= '9') { v = v * 10 + (c - '0'); if (!fill()) break; c = inbuf[inpos++]; }
    return v;
}

static void putch(char c) {
    if (outlen >= OUTCAP) { fwrite(outbuf, 1, OUTCAP, stdout); outlen = 0; }
    outbuf[outlen++] = c;
}

static void putll(long long v) {
    char tmp[24];
    int n = 0;
    do { tmp[n++] = (char)('0' + (v % 10)); v /= 10; } while (v > 0);
    while (n > 0) putch(tmp[--n]);
}

static long long gcdll(long long a, long long b) {
    while (b != 0) { long long r = a % b; a = b; b = r; }
    return a;
}

int main(void) {
    for (;;) {
        long long a = nextll();
        long long b = nextll();
        if (a == 0 && b == 0) break;
        putll(gcdll(a, b));
        putch('\n');
    }
    if (outlen > 0) fwrite(outbuf, 1, outlen, stdout);
    return 0;
}
