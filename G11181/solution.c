#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INP 1100000
#define OUTP 1048576
#define MAXW 1000000

static char inb[INP];
static char outb[OUTP];
static int outn;
static int wordOff[MAXW];
static unsigned short wordLen[MAXW];
static int order[MAXW];
static int wordCount;

static void flush(void) { if (outn) { fwrite(outb, 1, outn, stdout); outn = 0; } }
static void put(char c) { if (outn == OUTP) flush(); outb[outn++] = c; }

static int readAll(void) {
    int n = 0;
    for (;;) { int r = (int)fread(inb + n, 1, INP - n, stdin); if (r <= 0) break; n += r; if (n == INP) break; }
    return n;
}

static int cmpWord(const void *pa, const void *pb) {
    int a = *(const int *)pa;
    int b = *(const int *)pb;
    int oa = wordOff[a];
    int ob = wordOff[b];
    int la = wordLen[a];
    int lb = wordLen[b];
    int m = la < lb ? la : lb;
    int r = memcmp(inb + oa, inb + ob, (size_t)m);
    if (r) return r;
    return la - lb;
}

int main(void) {
    int n = readAll();
    int i = 0;
    while (i < n) {
        char c = inb[i];
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) {
            int start = i;
            while (i < n) {
                char d = inb[i];
                if (d >= 'A' && d <= 'Z') inb[i] = (char)(d + 32);
                if (inb[i] < 'a' || inb[i] > 'z') break;
                i++;
            }
            if (wordCount < MAXW) {
                wordOff[wordCount] = start;
                wordLen[wordCount] = (unsigned short)(i - start);
                wordCount++;
            }
        } else {
            i++;
        }
    }
    for (i = 0; i < wordCount; i++) order[i] = i;
    qsort(order, (size_t)wordCount, sizeof(int), cmpWord);
    for (i = 0; i < wordCount; i++) {
        int cur = order[i];
        int off = wordOff[cur];
        int len = wordLen[cur];
        if (i) {
            int prev = order[i - 1];
            if (len == wordLen[prev] && memcmp(inb + off, inb + wordOff[prev], (size_t)len) == 0) continue;
        }
        {
            int j;
            for (j = 0; j < len; j++) put(inb[off + j]);
            put('\n');
        }
    }
    flush();
    return 0;
}
