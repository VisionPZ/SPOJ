#include <stdio.h>
#include <stdlib.h>

#define INCAP 131072
#define OUTCAP 131072
#define LIMIT 10000000

static char inbuf[INCAP];
static char outbuf[OUTCAP];
static int inlen = 0, inpos = 0, outlen = 0;
static unsigned char composite[LIMIT + 1];
static int primes[664579];
static int primeCount = 0;

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

static void putstr(const char *s) { while (*s) putch(*s++); }

static void putll(long long v) {
    char tmp[24];
    int n = 0;
    do { tmp[n++] = (char)('0' + (v % 10)); v /= 10; } while (v > 0);
    while (n > 0) putch(tmp[--n]);
}

int main(void) {
    for (int i = 2; (long long)i * i <= LIMIT; i++) {
        if (!composite[i]) {
            for (long long j = (long long)i * i; j <= LIMIT; j += i) composite[(int)j] = 1;
        }
    }
    for (int i = 2; i <= LIMIT; i++) if (!composite[i]) primes[primeCount++] = i;

    int t = nextint();
    for (int caseIndex = 0; caseIndex < t; caseIndex++) {
        long long n = nextll();
        long long rem = n;
        long long base[32];
        int power[32];
        int fc = 0;
        for (int i = 0; i < primeCount; i++) {
            long long p = primes[i];
            if (p * p > rem) break;
            if (rem % p == 0) {
                int e = 0;
                while (rem % p == 0) { rem /= p; e++; }
                base[fc] = p; power[fc] = e; fc++;
            }
        }
        if (rem > 1) { base[fc] = rem; power[fc] = 1; fc++; }
        long long sigma = 1;
        for (int i = 0; i < fc; i++) {
            long long geom = 1, term = 1;
            for (int k = 0; k < power[i]; k++) { term *= base[i]; geom += term; }
            sigma *= geom;
        }
        for (int i = 0; i < fc; i++) { putll(base[i]); putch(' '); putll(power[i]); putch('\n'); }
        putstr("Sum Of Divisiors: ");
        putll(sigma);
        putch('\n');
        if (caseIndex < t - 1) putch('\n');
    }
    if (outlen > 0) fwrite(outbuf, 1, outlen, stdout);
    return 0;
}
