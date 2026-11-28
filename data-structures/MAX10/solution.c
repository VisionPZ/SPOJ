#include <stdio.h>
#include <stdlib.h>

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

static void putstr(const char *s) {
    while (*s) {
        if (outlen >= OUTCAP) { fwrite(outbuf, 1, OUTCAP, stdout); outlen = 0; }
        outbuf[outlen++] = *s++;
    }
}

static void putll(long long v) {
    char tmp[24];
    int n = 0;
    if (v < 0) { putstr("-"); v = -v; }
    do { tmp[n++] = (char)('0' + (v % 10)); v /= 10; } while (v > 0);
    while (n > 0) {
        if (outlen >= OUTCAP) { fwrite(outbuf, 1, OUTCAP, stdout); outlen = 0; }
        outbuf[outlen++] = tmp[--n];
    }
}

int main(void) {
    long long best = 0;
    for (int i = 0; i < 10; i++) {
        long long v = nextll();
        if (v > best) best = v;
    }
    putstr("Bilangan terbesar: ");
    putll(best);
    putstr("\n");
    if (outlen > 0) fwrite(outbuf, 1, outlen, stdout);
    return 0;
}
