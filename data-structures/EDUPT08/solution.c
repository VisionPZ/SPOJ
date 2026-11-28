#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define FLUSH_BYTES (1 << 17)

static unsigned char *indata;
static size_t inlen;
static size_t inpos;

static void read_all(void) {
    size_t cap = (size_t)1 << 24;
    unsigned char *buf = (unsigned char *)malloc(cap + 1);
    size_t len = 0;
    for (;;) {
        ssize_t got = read(0, buf + len, cap - len);
        if (got <= 0) {
            break;
        }
        len += (size_t)got;
        if (len == cap) {
            cap *= 2;
            buf = (unsigned char *)realloc(buf, cap + 1);
        }
    }
    buf[len] = 0;
    indata = buf;
    inlen = len;
}

static long long next_int(void) {
    while (inpos < inlen && (indata[inpos] < '0' || indata[inpos] > '9')) {
        inpos++;
    }
    long long value = 0;
    while (inpos < inlen && indata[inpos] >= '0' && indata[inpos] <= '9') {
        value = value * 10 + (indata[inpos] - '0');
        inpos++;
    }
    return value;
}

static char outbuf[FLUSH_BYTES];
static size_t outlen;

static void flush_out(void) {
    if (outlen > 0) {
        fwrite(outbuf, 1, outlen, stdout);
        outlen = 0;
    }
}

static void put_byte(int c) {
    if (outlen == FLUSH_BYTES) {
        flush_out();
    }
    outbuf[outlen++] = (char)c;
}

static void put_int(long long value) {
    char digits[24];
    int count = 0;
    if (value < 0) {
        put_byte('-');
        value = -value;
    }
    do {
        digits[count++] = (char)('0' + value % 10);
        value /= 10;
    } while (value > 0);
    while (count > 0) {
        put_byte(digits[--count]);
    }
}

int main(void) {
    read_all();
    int n = (int)next_int();
    int m = (int)next_int();
    static int first[64];
    static int second[64];
    for (int i = 0; i < n; i++) {
        first[i] = (int)next_int();
    }
    for (int i = 0; i < m; i++) {
        second[i] = (int)next_int();
    }
    int i = 0;
    int j = 0;
    int intersection_empty = 1;
    while (i < n && j < m) {
        if (first[i] == second[j]) {
            put_int(first[i]);
            put_byte(' ');
            intersection_empty = 0;
            i++;
            j++;
        } else if (first[i] < second[j]) {
            i++;
        } else {
            j++;
        }
    }
    if (intersection_empty) {
        put_byte(' ');
    }
    put_byte('\n');
    i = 0;
    j = 0;
    while (i < n || j < m) {
        if (j >= m || (i < n && first[i] < second[j])) {
            put_int(first[i]);
            put_byte(' ');
            i++;
        } else if (i >= n || second[j] < first[i]) {
            put_int(second[j]);
            put_byte(' ');
            j++;
        } else {
            put_int(first[i]);
            put_byte(' ');
            i++;
            j++;
        }
    }
    if (n == 0 && m == 0) {
        put_byte(' ');
    }
    put_byte('\n');
    flush_out();
    return 0;
}
