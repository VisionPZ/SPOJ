# ALGOUPT09 — Karaokêeeeeeee (SPOJ)

<https://www.spoj.com/problems/ALGOUPT09/>

## Problem

Translate each lyric line with a Japanese-to-Portuguese dictionary and print the result. Words missing from the dictionary stay unchanged.

Input starts with T test cases. Each case starts with M dictionary entries and N lyric lines. Each entry is a Japanese word on one line and its Portuguese translation on the next line. A translation may contain several lowercase words. Each lyric line holds lowercase words separated by single spaces and may be empty. No line exceeds 80 letters.

Output has N translated lines per case, followed by one blank line. The blank line appears after the final case as well.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | not bounded in the statement |
| dictionary words M | 1 to 1000000 |
| lyric lines N | 1 to 1000 |
| line length | at most 80 letters |
| judge limit | 1000 ms, 1536 MB |

The large dictionary bound drives the choice of a hash table.

Sample input:

```
1
4 3
galaxy
cara tossiu
kagayaku
canalha do
atsuki
alto que
yuushi
util
o galaxy
o galaxy
o kagayaku atsuki yuushi
```

The sample maps four Japanese words to Portuguese phrases.

Sample output:

```
o cara tossiu
o cara tossiu
o canalha do alto que util

```

The blank line after the third translated line closes the case.

## Idea

A dictionary is like a label maker: each Japanese word maps to one fixed phrase. Store the pairs in a hash table, then replace each lyric word by its stored phrase.

A linear search through M entries per word would cost O(M) per lookup. Hashing finds each phrase in expected constant time and keeps the whole case near linear.

One table build plus one pass over lyric lines gives the answer.

## Why It Works

1. Each Japanese word appears once per case, so one table slot holds its phrase.
2. Lyric words are separated by single spaces, so a token walk finds exact keys.
3. A key miss leaves the original word in place.
4. A phrase with several words is inserted as one joined string.
5. One blank line after each case matches the output contract.

The main terms:

| term | meaning |
|---|---|
| `table` | open-addressing hash table mapping Japanese words to Portuguese phrases |
| `table_init` | allocates a zeroed table and arena for one case |
| `next_line` | slices the next input line into `line_start` and `line_len` |
| `table_find` | looks up one lyric word in `table` |
| `case_count` | number of test cases to translate |

The table maps each helper to one part of the translation step.

A trace from the generator with visible numbers:

```
dictionary words: 4
lyric lines: 3
lyric words in last line: 4
third output length: 26
blank lines appended: 1
```

The trace shows the four words in the last sample line and the final blank line.

## Code

**Input, scanner, and buffered output.** The driver reads stdin into `indata`, parses integers and lines, and buffers writes in `outbuf`.

```c
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
```

Each line slice tracks `line_start` and `line_len` without extra allocations.

**Hash table and driver.** Open addressing stores Japanese-to-Portuguese pairs per case, then writes translated lyric lines and a blank line.

```c
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
```

The FNV-1a hash scans each token slice once and emits unchanged words when absent from `table`.

## Complexity

Dictionary build and lyric translation are the two costs per case.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| table build | M insertions | M stored phrases |
| lyric translation | one lookup per lyric word | one output line |
| output | block writes | block buffer |

The table bound M dominates space and build time.

| measure | Big O |
|---|---|
| time | O(L + M + W) per case |
| space | O(L + M) |

L is the input length and W is the total number of lyric words; a linear dictionary scan would cost O(M) per word.

Hashing turns each lookup into one table access, so one pass over the lyrics suffices.
