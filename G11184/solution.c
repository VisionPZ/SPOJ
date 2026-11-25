#include <stdio.h>
#include <stdlib.h>

#define INP 33554432
#define OUTP 1048576
#define MAXN 3000

static char inb[INP];
static char outb[OUTP];
static int outn;
static int seq[MAXN];
static unsigned char seen[MAXN];

static void flush(void) { if (outn) { fwrite(outb, 1, outn, stdout); outn = 0; } }
static void put(char c) { if (outn == OUTP) flush(); outb[outn++] = c; }
static void putLit(const char *s) { while (*s) put(*s++); }

static int readAll(void) {
    int n = 0;
    for (;;) { int r = (int)fread(inb + n, 1, INP - n, stdin); if (r <= 0) break; n += r; if (n == INP) break; }
    return n;
}

static int nextInt(const char *s, int n, int *p, int *v) {
    int i = *p;
    while (i < n && s[i] != '-' && (s[i] < '0' || s[i] > '9')) i++;
    if (i >= n) { *p = i; return 0; }
    int neg = 0;
    if (s[i] == '-') { neg = 1; i++; }
    int x = 0;
    while (i < n && s[i] >= '0' && s[i] <= '9') { x = x * 10 + (s[i] - '0'); i++; }
    *p = i;
    *v = neg ? -x : x;
    return 1;
}

int main(void) {
    int n = readAll();
    int p = 0;
    for (;;) {
        int cnt;
        if (!nextInt(inb, n, &p, &cnt)) break;
        if (cnt == 0) break;
        int i, ok = 1, distinct = 0;
        for (i = 0; i < cnt; i++) if (!nextInt(inb, n, &p, &seq[i])) { ok = 0; break; }
        if (!ok) break;
        for (i = 0; i + 1 < cnt; i++) {
            int d = seq[i + 1] - seq[i];
            if (d < 0) d = -d;
            if (d < 1 || d > cnt - 1 || seen[d]) ok = 0;
            else { seen[d] = 1; distinct++; }
        }
        if (distinct != cnt - 1) ok = 0;
        putLit(ok ? "Jolly\n" : "Not jolly\n");
        for (i = 1; i < cnt; i++) seen[i] = 0;
    }
    flush();
    return 0;
}
