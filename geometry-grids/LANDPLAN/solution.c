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

static int nextint(void) {
    int c;
    do { if (!fill()) return 0; c = inbuf[inpos++]; } while (c < '0' || c > '9');
    int v = 0;
    while (c >= '0' && c <= '9') { v = v * 10 + (c - '0'); if (!fill()) break; c = inbuf[inpos++]; }
    return v;
}

static void putch(char c) {
    if (outlen >= OUTCAP) { fwrite(outbuf, 1, OUTCAP, stdout); outlen = 0; }
    outbuf[outlen++] = c;
}

int main(void) {
    int t = nextint();
    for (int caseIndex = 0; caseIndex < t; caseIndex++) {
        int n = nextint();
        for (int i = 0; i < n; i++) putch('#');
        putch('\n');
        for (int row = 1; row < n - 1; row++) {
            putch('#');
            for (int col = 1; col < n - 1; col++) putch('.');
            if (n >= 2) putch('#');
            putch('\n');
        }
        if (n >= 2) {
            for (int i = 0; i < n; i++) putch('#');
            putch('\n');
        }
        putch('\n');
    }
    if (outlen > 0) fwrite(outbuf, 1, outlen, stdout);
    return 0;
}
