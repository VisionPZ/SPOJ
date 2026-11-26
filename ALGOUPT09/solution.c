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

static size_t line_start;
static size_t line_len;

static int next_line(void) {
    if (inpos >= inlen) {
        line_start = inpos;
        line_len = 0;
        return 0;
    }
    size_t scan = inpos;
    while (scan < inlen && indata[scan] != '\n') {
        scan++;
    }
    size_t end = scan;
    if (end > inpos && indata[end - 1] == '\r') {
        end--;
    }
    line_start = inpos;
    line_len = end - inpos;
    inpos = scan;
    if (scan < inlen) {
        inpos = scan + 1;
    }
    return 1;
}

static void skip_line(void) {
    while (inpos < inlen && indata[inpos] != '\n') {
        inpos++;
    }
    if (inpos < inlen) {
        inpos++;
    }
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

typedef struct {
    char *key;
    char *value;
} Entry;

static Entry *table;
static size_t table_mask;
static char *arena;
static size_t arena_used;

static unsigned long long hash_bytes(const char *s, size_t n) {
    unsigned long long h = 1469598915534084384ULL;
    for (size_t i = 0; i < n; i++) {
        h ^= (unsigned char)s[i];
        h *= 1099511628211ULL;
    }
    return h;
}

static void table_init(size_t hint, size_t extra) {
    size_t size = 1;
    while (size < hint * 2) {
        size <<= 1;
    }
    table = (Entry *)calloc(size, sizeof(Entry));
    table_mask = size - 1;
    arena = (char *)malloc(extra + 2 * hint + 16);
    arena_used = 0;
}

static char *arena_copy(const char *s, size_t n) {
    char *p = arena + arena_used;
    memcpy(p, s, n);
    p[n] = 0;
    arena_used += n + 1;
    return p;
}

static void table_insert(const char *key, size_t key_len, const char *value, size_t value_len) {
    char *stored_key = arena_copy(key, key_len);
    char *stored_value = arena_copy(value, value_len);
    size_t slot = (size_t)(hash_bytes(stored_key, key_len) & table_mask);
    while (table[slot].key != NULL) {
        if (strcmp(table[slot].key, stored_key) == 0) {
            table[slot].value = stored_value;
            return;
        }
        slot = (slot + 1) & table_mask;
    }
    table[slot].key = stored_key;
    table[slot].value = stored_value;
}

static const char *table_find(const char *key, size_t key_len) {
    size_t slot = (size_t)(hash_bytes(key, key_len) & table_mask);
    while (table[slot].key != NULL) {
        if (memcmp(table[slot].key, key, key_len) == 0 && table[slot].key[key_len] == 0) {
            return table[slot].value;
        }
        slot = (slot + 1) & table_mask;
    }
    return NULL;
}

int main(void) {
    read_all();
    long long case_count = next_int();
    for (long long case_index = 0; case_index < case_count; case_index++) {
        long long word_count = next_int();
        long long lyric_count = next_int();
        skip_line();
        table_init((size_t)word_count + 1, inlen);
        for (long long word_index = 0; word_index < word_count; word_index++) {
            next_line();
            size_t key_start = line_start;
            size_t key_len = line_len;
            next_line();
            table_insert((const char *)indata + key_start, key_len,
                         (const char *)indata + line_start, line_len);
        }
        for (long long lyric_index = 0; lyric_index < lyric_count; lyric_index++) {
            next_line();
            size_t walk = 0;
            while (walk < line_len) {
                if (walk > 0) {
                    put_byte(' ');
                }
                size_t token_end = walk;
                while (token_end < line_len && indata[line_start + token_end] != ' ') {
                    token_end++;
                }
                const char *found = table_find((const char *)indata + line_start + walk,
                                              token_end - walk);
                if (found != NULL) {
                    put_mem(found, strlen(found));
                } else {
                    put_mem((const char *)indata + line_start + walk, token_end - walk);
                }
                walk = token_end + 1;
            }
            put_byte('\n');
        }
        put_byte('\n');
    }
    flush_out();
    return 0;
}
