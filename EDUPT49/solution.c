#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

static void put_mem(const char *s, size_t n) {
    while (n > 0) {
        if (outlen == FLUSH_BYTES) {
            flush_out();
        }
        size_t take = FLUSH_BYTES - outlen;
        if (take > n) {
            take = n;
        }
        memcpy(outbuf + outlen, s, take);
        outlen += take;
        s += take;
        n -= take;
    }
}

int main(void) {
    read_all();
    int car_count = (int)next_int();
    static int arrival[1001];
    static int desired[1001];
    static int maneuver_stack[1001];
    static char operation_text[24000];
    for (int i = 0; i < car_count; i++) {
        arrival[i] = (int)next_int();
    }
    for (int i = 0; i < car_count; i++) {
        desired[i] = (int)next_int();
    }
    size_t operation_len = 0;
    int top = 0;
    int next_car = 0;
    int possible = 1;
    for (int d = 0; d < car_count; d++) {
        while ((top == 0 || maneuver_stack[top - 1] != desired[d]) && next_car < car_count) {
            operation_text[operation_len++] = 'P';
            operation_text[operation_len++] = 'U';
            operation_text[operation_len++] = 'S';
            operation_text[operation_len++] = 'H';
            operation_text[operation_len++] = '\n';
            maneuver_stack[top++] = arrival[next_car++];
        }
        if (top > 0 && maneuver_stack[top - 1] == desired[d]) {
            operation_text[operation_len++] = 'P';
            operation_text[operation_len++] = 'O';
            operation_text[operation_len++] = 'P';
            operation_text[operation_len++] = '\n';
            top--;
        } else {
            possible = 0;
            break;
        }
    }
    if (possible) {
        put_mem(operation_text, operation_len);
    } else {
        put_mem("IMPOSSIVEL\n", 11);
    }
    flush_out();
    return 0;
}
