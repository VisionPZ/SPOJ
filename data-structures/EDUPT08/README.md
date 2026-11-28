# EDUPT08 — Conjuntos (SPOJ)

<https://www.spoj.com/problems/EDUPT08/>

## Problem

Two sorted sets of numbers are given. Print their intersection on one line and their union on the next line.

Input starts with the sizes n and m, followed by the n values of the first set and the m values of the second set. An empty set is a blank line. Each output line ends with a space followed by a newline, and an empty line holds that space alone.

The sets stay small.

| item | bound |
|---|---|
| sizes n and m | 0 to 30 |
| each element | 0 to 1000, sorted ascending |
| judge limit | 1000 ms, 1536 MB |

Sorted input lets one pass over both lists produce each answer.

Sample input:

```
5 6
3 4 5 7 22
5 7 9 18 22 25
```

Sample output:

```
5 7 22 
3 4 5 7 9 18 22 25 
```

## Idea

Walk two sorted lines like two zippers, like matching names on two sorted guest lists.

The real algorithm is a two-pointer merge. Equal values go to the intersection and once to the union. Smaller values go only to the union. A nested search would compare every pair, while the merge advances each cursor once. The takeaway is to exploit the given sort order.

## Why It Works

1. Both `first` and `second` arrive in ascending order.
2. When the two cursor values match, the value belongs to both sets.
3. When they differ, the smaller value belongs only to the union.
4. Advancing the smaller cursor keeps both lists aligned.
5. Remaining tail values append directly to the union.

| term | meaning |
|---|---|
| `i` | cursor in the first set `first` |
| `j` | cursor in the second set `second` |
| `intersection_empty` | flag checking whether the intersection line is empty |
| `outbuf` | output buffer writing both result lines |

Each cursor moves forward only, so no value is compared twice.

For the sample the cursors meet at 5, then 7, then 22. Those three values form the intersection. The merge also emits 3, 4, 9, 18 and 25 on the union line.

An empty result line is written as a single space before the newline. This matches the stated output contract exactly.

## Code

**Input and scanner.** One read loop collects the stream, and a digit scanner yields each value.

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
```

The scanner skips spaces and blank lines.
Each set element is read as a plain integer.
Values are sorted, so no sorting step appears.

**Input and first pass.** The reader loads both sets and computes the intersection with matched cursors.

```c
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
```

Equal values advance both cursors together.
A smaller value advances only its own cursor.
Every emitted value carries a trailing space.

**Second pass and output.** A fresh merge builds the union, then both lines are buffered.

```c
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
```

Exhausted sets fall through to the other side.
Matched values are added once to the union.
An empty line still writes one space.

## Complexity

Both passes walk the two sets once each.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | two integer arrays |
| intersection pass | up to n plus m cursor steps | one text buffer |
| union pass | up to n plus m cursor steps | one text buffer |

The counts below describe the whole run.

| measure | Big O |
|---|---|
| time | O(n + m) |
| space | O(n + m) |

Testing every value of one set against every value of the other would take O(n times m), while the merge finishes in linear time.
