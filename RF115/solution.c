#include <stdio.h>
#include <stdlib.h>

#define INP 1100000
#define OUTP 1048576

static char inb[INP];
static char outb[OUTP];
static int outn;

static void flush(void) { if (outn) { fwrite(outb, 1, outn, stdout); outn = 0; } }
static void put(char c) { if (outn == OUTP) flush(); outb[outn++] = c; }
static void putStr(const char *s, int n) { while (n--) put(*s++); }
static void putInt(long long x) { char b[24]; int k = 0; int neg = 0; if (x < 0) { neg = 1; x = -x; } if (!x) { put('0'); return; } while (x > 0) { b[k++] = (char)('0' + x % 10); x /= 10; } if (neg) put('-'); while (k) put(b[--k]); }

static int readAll(void) {
    int n = 0;
    for (;;) { int r = (int)fread(inb + n, 1, INP - n, stdin); if (r <= 0) break; n += r; if (n == INP) break; }
    return n;
}

static int nextInt(const char *s, int n, int *p, long long *v) {
    int i = *p;
    while (i < n && s[i] != '-' && (s[i] < '0' || s[i] > '9')) i++;
    if (i >= n) { *p = i; return 0; }
    int neg = 0;
    if (s[i] == '-') { neg = 1; i++; }
    long long x = 0;
    while (i < n && s[i] >= '0' && s[i] <= '9') { x = x * 10 + (s[i] - '0'); i++; }
    *p = i;
    *v = neg ? -x : x;
    return 1;
}

int main(void) {
    int n = readAll();
    int p = 0;
    long long dim, cat;
    if (!nextInt(inb, n, &p, &dim)) return 0;
    if (!nextInt(inb, n, &p, &cat)) return 0;
    long long i, j, sum = 0, mx = -1000000000000LL, mn = 1000000000000LL;
    for (i = 0; i < dim; i++) {
        for (j = 0; j < dim; j++) {
            if (j) put(' ');
            long long v = i + j - cat;
            putInt(v);
            sum += v;
            if (v > mx) mx = v;
            if (v < mn) mn = v;
        }
        put('\n');
    }
    if (dim > 0) { putInt(sum); put('\n'); putInt(mx); put('\n'); putInt(mn); put('\n'); }
    flush();
    return 0;
}
