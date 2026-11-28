# EDUPT27 — Eliminando uma sequencia várias vezes (SPOJ)

<https://www.spoj.com/problems/EDUPT27/>

## Problem

A list of integers and a pattern of integers are given, each ended by the value -1. Remove every consecutive block that matches the pattern exactly, in the same order, and print what remains.

Input has two lines. The first line holds the list, and the second holds the pattern. Both lines stop at -1, which is not part of either sequence. A pattern may be empty, and it may appear many times.

The values are bounded.

| item | bound |
|---|---|
| list and pattern values | 0 to 32000 |
| terminator | -1 |
| list length | thousands of elements |
| judge limit | 1000 ms, 1536 MB |

The pattern must appear as one unbroken run. Removing a block may create a new block at the join.

Sample input:

```
3 5 1 8 9 5 7 -1
5 1 8 -1
```

Sample output:

```
3 9 5 7
```

## Idea

Keep a stack of kept values, like a line of boxes that collapses whenever a matching group reaches the end.

The real algorithm is a single left-to-right pass with a stack and a suffix check. Each value is pushed once. When the last pattern-length values match the pattern, they are popped together. A repeated search from the start would rescan the list after every deletion and cost far more. The takeaway is to notice that every removable block ends at the value currently read.

## Why It Works

1. A removable block ends at the value currently being read.
2. Before that value, the stack holds all earlier values with prior blocks already removed.
3. If the last `pattern_len` values equal `pattern`, that block is removed now.
4. Popping exposes earlier values, so a new match at the join is caught on the next push.
5. Values that never form a block stay on the stack in their original order.

| term | meaning |
|---|---|
| `list_values` | values read from the first line |
| `pattern` | values read from the second line |
| `survivors` | stack of values after all removals |
| `matches` | nonzero when the stack suffix equals `pattern` |

Each value enters the stack once and is popped at most once.

For the first sample the list is 3, 5, 1, 8, 9, 5, 7 and the pattern is 5, 1, 8. The stack reaches 3, 5, 1, 8 and the suffix matches. Those three values are popped, leaving 3, then 9, 5 and 7 join. The result is 3, 9, 5, 7.

The cascade case uses list 10, 4, 6, 8, 4, 6, 8, 12, 12, 9, 1, 3 and pattern 4, 6, 8, 12. The first match pops out, and the second 12 completes a new match. The result is 10, 9, 1, 3.

An empty pattern triggers no check, so the list is printed unchanged. The output separates values with single spaces and ends with a newline.

## Code

**Input, scanner, and vector buffer.** The reader captures `indata`, scans signed integers, and prepares `outbuf` and dynamic `IntVec` arrays.

```c
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
```

Dynamic `IntVec` buffers grow by doubling with `realloc`.

**Stack removal and output.** Each value enters `survivors`, pops whenever the suffix matches `pattern`, and flushes remaining items.

```c
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
```

Every surviving item prints with a separating space and final newline.

## Complexity

The pass pushes each list value once and checks a pattern-length suffix.

| phase | time | space |
|---|---|---|
| input read | one pass over the stream | two integer arrays |
| stack pass | one push per list value | one integer stack |
| suffix check | up to pattern length per value | constant |
| output | one line | one output buffer |

The counts below describe the whole run.

| measure | Big O |
|---|---|
| time | O(list length times pattern length) |
| space | O(list length plus pattern length) |

Restarting a full scan after every deletion would repeat work on the same prefix, while the stack settles each block as soon as it forms.
