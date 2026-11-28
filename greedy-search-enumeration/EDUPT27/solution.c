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
    while (inpos < inlen && (indata[inpos] < '0' || indata[inpos] > '9') && indata[inpos] != '-') {
        inpos++;
    }
    int sign = 1;
    if (inpos < inlen && indata[inpos] == '-') {
        sign = -1;
        inpos++;
    }
    long long value = 0;
    while (inpos < inlen && indata[inpos] >= '0' && indata[inpos] <= '9') {
        value = value * 10 + (indata[inpos] - '0');
        inpos++;
    }
    return sign * value;
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

typedef struct {
    int *data;
    size_t len;
    size_t cap;
} IntVec;

static void iv_push(IntVec *v, int value) {
    if (v->len == v->cap) {
        v->cap = v->cap > 0 ? v->cap * 2 : 1024;
        v->data = (int *)realloc(v->data, v->cap * sizeof(int));
    }
    v->data[v->len++] = value;
}

int main(void) {
    read_all();
    IntVec list_values = {NULL, 0, 0};
    IntVec pattern = {NULL, 0, 0};
    IntVec survivors = {NULL, 0, 0};
    for (;;) {
        long long scanned = next_int();
        if (scanned == -1) {
            break;
        }
        iv_push(&list_values, (int)scanned);
    }
    for (;;) {
        long long scanned = next_int();
        if (scanned == -1) {
            break;
        }
        iv_push(&pattern, (int)scanned);
    }
    size_t pattern_len = pattern.len;
    for (size_t walk = 0; walk < list_values.len; walk++) {
        iv_push(&survivors, list_values.data[walk]);
        if (pattern_len > 0 && survivors.len >= pattern_len) {
            size_t base = survivors.len - pattern_len;
            int matches = 1;
            for (size_t probe = 0; probe < pattern_len; probe++) {
                if (survivors.data[base + probe] != pattern.data[probe]) {
                    matches = 0;
                    break;
                }
            }
            if (matches) {
                survivors.len -= pattern_len;
            }
        }
    }
    for (size_t k = 0; k < survivors.len; k++) {
        if (k > 0) {
            put_byte(' ');
        }
        put_int(survivors.data[k]);
    }
    put_byte('\n');
    flush_out();
    return 0;
}
