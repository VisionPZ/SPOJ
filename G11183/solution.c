#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INP 16777216
#define OUTP 1048576
#define MAXB 1000

static char inb[INP];
static char outb[OUTP];
static int outn;
static int pile[MAXB][MAXB];
static int size_[MAXB];
static int pos[MAXB];
static int dep[MAXB];
static int blocks;

static void flush(void) { if (outn) { fwrite(outb, 1, outn, stdout); outn = 0; } }
static void put(char c) { if (outn == OUTP) flush(); outb[outn++] = c; }
static void putInt(int x) { char b[12]; int k = 0; if (!x) { put('0'); return; } while (x > 0) { b[k++] = (char)('0' + x % 10); x /= 10; } while (k) put(b[--k]); }

static int readAll(void) {
    int n = 0;
    for (;;) { int r = (int)fread(inb + n, 1, INP - n, stdin); if (r <= 0) break; n += r; if (n == INP) break; }
    return n;
}

static int nextToken(const char *s, int n, int *p, const char **tok, int *len) {
    int i = *p;
    while (i < n && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n' || s[i] == '\r')) i++;
    if (i >= n) { *p = i; return 0; }
    int st = i;
    while (i < n && s[i] != ' ' && s[i] != '\t' && s[i] != '\n' && s[i] != '\r') i++;
    *p = i;
    *tok = s + st;
    *len = i - st;
    return 1;
}

static int homePut(int b) {
    int h = size_[b];
    pile[b][h] = b;
    size_[b] = h + 1;
    pos[b] = b;
    dep[b] = h;
    return h;
}

static void returnAbove(int p, int h) {
    while (size_[p] > h + 1) {
        int t = size_[p] - 1;
        int b = pile[p][t];
        size_[p] = t;
        homePut(b);
    }
}

int main(void) {
    int n = readAll();
    int p = 0;
    const char *tok;
    int tl, i, j;
    if (!nextToken(inb, n, &p, &tok, &tl)) return 0;
    {
        int v = 0;
        for (i = 0; i < tl; i++) v = v * 10 + (tok[i] - '0');
        blocks = v;
    }
    for (i = 0; i < blocks; i++) { pile[i][0] = i; size_[i] = 1; pos[i] = i; dep[i] = 0; }
    for (;;) {
        if (!nextToken(inb, n, &p, &tok, &tl)) break;
        if (tl == 4 && tok[0] == 'q') break;
        int isPile = (tl == 4 && tok[0] == 'p');
        if (!nextToken(inb, n, &p, &tok, &tl)) break;
        int a = 0;
        for (i = 0; i < tl; i++) a = a * 10 + (tok[i] - '0');
        if (!nextToken(inb, n, &p, &tok, &tl)) break;
        int isOnto = (tl == 4 && tok[0] == 'o' && tok[1] == 'n');
        if (!nextToken(inb, n, &p, &tok, &tl)) break;
        int b = 0;
        for (i = 0; i < tl; i++) b = b * 10 + (tok[i] - '0');
        int pa = pos[a], ha = dep[a];
        int pb = pos[b], hb = dep[b];
        if (isPile) {
            if (pa == pb) continue;
            if (isOnto) returnAbove(pb, hb);
            int cnt = size_[pa] - ha;
            int base = size_[pb];
            for (i = 0; i < cnt; i++) {
                int blk = pile[pa][ha + i];
                pile[pb][base + i] = blk;
                pos[blk] = pb;
                dep[blk] = base + i;
            }
            size_[pb] = base + cnt;
            size_[pa] = ha;
        } else {
            returnAbove(pa, ha);
            if (isOnto) {
                pb = pos[b];
                hb = dep[b];
                returnAbove(pb, hb);
            }
            pa = pos[a];
            ha = dep[a];
            pb = pos[b];
            size_[pa] = ha;
            int nh = size_[pb];
            pile[pb][nh] = a;
            size_[pb] = nh + 1;
            pos[a] = pb;
            dep[a] = nh;
        }
    }
    for (i = 0; i < blocks; i++) {
        putInt(i);
        put(':');
        for (j = 0; j < size_[i]; j++) { put(' '); putInt(pile[i][j]); }
        put('\n');
    }
    flush();
    return 0;
}
