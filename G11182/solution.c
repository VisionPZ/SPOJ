#include <stdio.h>
#include <string.h>

#define INP 16777216
#define OUTP 1048576
#define WLEN 16
#define RCW 128

static char inb[INP];
static char outb[OUTP];
static int outn;

static void flush(void) { if (outn) { fwrite(outb, 1, outn, stdout); outn = 0; } }
static void put(char c) { if (outn == OUTP) flush(); outb[outn++] = c; }
static void putLit(const char *s) { while (*s) put(*s++); }

static int readAll(void) {
    int n = 0;
    for (;;) { int r = (int)fread(inb + n, 1, INP - n, stdin); if (r <= 0) break; n += r; if (n == INP) break; }
    return n;
}

static int crossAt(const char *hz, int lh, const char *vt, int lv, int *ci, int *vi) {
    int i, j;
    for (i = 0; i < lh; i++) {
        for (j = 0; j < lv; j++) {
            if (hz[i] == vt[j]) { *ci = i; *vi = j; return 1; }
        }
    }
    return 0;
}

static void putRow(int c1, char a, int c2, char b) {
    char line[RCW];
    int i, last = -1;
    for (i = 0; i < RCW; i++) line[i] = ' ';
    if (a) { line[c1] = a; last = c1; }
    if (b) { line[c2] = b; if (c2 > last) last = c2; }
    for (i = 0; i <= last; i++) put(line[i]);
    put('\n');
}

int main(void) {
    int n = readAll();
    int p = 0;
    int setNo = 0;
    while (p < n) {
        int s = p;
        while (p < n && inb[p] != '\n') p++;
        int e = p;
        if (p < n) p++;
        while (e > s && (inb[e - 1] == '\r' || inb[e - 1] == ' ' || inb[e - 1] == '\t')) e--;
        if (e == s) continue;
        if (e - s == 1 && inb[s] == '#') break;
        {
            char *w[4];
            int wl[4];
            int wc = 0;
            int i = s;
            while (i < e && wc < 4) {
                while (i < e && (inb[i] == ' ' || inb[i] == '\t')) i++;
                int st = i;
                while (i < e && inb[i] != ' ' && inb[i] != '\t') i++;
                if (i > st) { w[wc] = inb + st; wl[wc] = i - st; wc++; }
            }
            if (wc != 4) continue;
            if (setNo++) put('\n');
            for (i = s; i < e; i++) put(inb[i]);
            put('\n');
            int c1, v1, c2, v2;
            int ok = crossAt(w[0], wl[0], w[1], wl[1], &c1, &v1) && crossAt(w[2], wl[2], w[3], wl[3], &c2, &v2);
            if (!ok) {
                putLit("Unable to make two crosses\n");
                continue;
            }
            int col2 = wl[0] + 3 + c2;
            int above = v1 > v2 ? v1 : v2;
            int r;
            for (r = 0; r < above; r++) {
                int i1 = r - (above - v1);
                int i2 = r - (above - v2);
                putRow(c1, i1 >= 0 ? w[1][i1] : 0, col2, i2 >= 0 ? w[3][i2] : 0);
            }
            for (r = 0; r < wl[0]; r++) put(w[0][r]);
            put(' '); put(' '); put(' ');
            for (r = 0; r < wl[2]; r++) put(w[2][r]);
            put('\n');
            int b1 = wl[1] - v1 - 1;
            int b2 = wl[3] - v2 - 1;
            int below = b1 > b2 ? b1 : b2;
            for (r = 0; r < below; r++) {
                int i1 = v1 + 1 + r;
                int i2 = v2 + 1 + r;
                putRow(c1, i1 < wl[1] ? w[1][i1] : 0, col2, i2 < wl[3] ? w[3][i2] : 0);
            }
        }
    }
    flush();
    return 0;
}
