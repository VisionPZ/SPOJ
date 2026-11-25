#include <stdio.h>

#define INP 1048576
#define OUTP 1048576
#define TOP 1000

static char inb[INP];
static char outb[OUTP];
static int outn;
static int prime[TOP + 1];
static int list[TOP];

static void flush(void) { if (outn) { fwrite(outb, 1, outn, stdout); outn = 0; } }
static void put(char c) { if (outn == OUTP) flush(); outb[outn++] = c; }
static void putInt(int x) { char b[12]; int k = 0; if (!x) { put('0'); return; } while (x > 0) { b[k++] = (char)('0' + x % 10); x /= 10; } while (k) put(b[--k]); }

static int readAll(void) {
    int n = 0;
    for (;;) { int r = (int)fread(inb + n, 1, INP - n, stdin); if (r <= 0) break; n += r; if (n == INP) break; }
    return n;
}

static int firstInt(const char *s, int n) {
    int i = 0, v = 0;
    while (i < n && (s[i] < '0' || s[i] > '9')) i++;
    while (i < n && s[i] >= '0' && s[i] <= '9') { v = v * 10 + (s[i] - '0'); i++; }
    return v;
}

int main(void) {
    int i, j, rows, cnt = 0, used = 0, w = 0;
    for (i = 2; i <= TOP; i++) prime[i] = 1;
    for (i = 2; i * i <= TOP; i++) if (prime[i]) for (j = i * i; j <= TOP; j += i) prime[j] = 0;
    for (i = TOP; i >= 2; i--) if (prime[i]) list[cnt++] = i;
    rows = firstInt(inb, readAll());
    while (rows > 0 && used < cnt) {
        w++;
        for (i = 0; i < w && used < cnt; i++) { if (i) put(' '); putInt(list[used++]); }
        put('\n');
        rows--;
    }
    flush();
    return 0;
}
