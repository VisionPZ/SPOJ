#include <stdio.h>

static char inbuf[131072];
static int inlen = 0, inpos = 0;

static int fill(void) {
    if (inpos >= inlen) {
        inlen = (int)fread(inbuf, 1, sizeof inbuf, stdin);
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

int main(void) {
    long long n = nextll();
    long long t = n, r = 0;
    while (t > 0) { r = r * 10 + t % 10; t /= 10; }
    if (r == n) fputs("YA\n", stdout);
    else fputs("TIDAK\n", stdout);
    return 0;
}
