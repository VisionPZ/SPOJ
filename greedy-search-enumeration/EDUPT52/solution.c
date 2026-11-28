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

typedef struct {
    long long turn_count;
    int process_id;
} ProcessRecord;

static int compare_records(const void *left, const void *right) {
    const ProcessRecord *a = (const ProcessRecord *)left;
    const ProcessRecord *b = (const ProcessRecord *)right;
    if (a->turn_count < b->turn_count) {
        return -1;
    }
    if (a->turn_count > b->turn_count) {
        return 1;
    }
    if (a->process_id < b->process_id) {
        return -1;
    }
    if (a->process_id > b->process_id) {
        return 1;
    }
    return 0;
}

int main(void) {
    read_all();
    int process_count = (int)next_int();
    long long quantum = next_int();
    ProcessRecord *processes = (ProcessRecord *)malloc((size_t)process_count * sizeof(ProcessRecord));
    for (int i = 0; i < process_count; i++) {
        long long burst = next_int();
        processes[i].turn_count = (burst + quantum - 1) / quantum;
        processes[i].process_id = i + 1;
    }
    qsort(processes, (size_t)process_count, sizeof(ProcessRecord), compare_records);
    for (int i = 0; i < process_count; i++) {
        if (i > 0) {
            put_byte(' ');
        }
        put_int(processes[i].process_id);
    }
    put_byte('\n');
    flush_out();
    return 0;
}
