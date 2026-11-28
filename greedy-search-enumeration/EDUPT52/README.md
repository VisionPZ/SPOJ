# EDUPT52 — Round Robin Task Scheduler (SPOJ)

<https://www.spoj.com/problems/EDUPT52/>

## Problem

N processes arrive in order and share one CPU under Round Robin scheduling. Report the process IDs in the exact order in which they finish.

The first line holds N and Q, with 1 ≤ N ≤ 100000 and 1 ≤ Q ≤ 10^9. The second line holds the N burst times T_i, each between 1 and 10^9. Print one line with N IDs separated by single spaces.

| item | bound |
|---|---|
| processes N | 1 to 100000 |
| quantum Q | 1 to 10^9 |
| burst T_i | 1 to 10^9 |
| judge limit | 1000 ms, 1536 MB |

A process leaves the queue for good on the visit that finishes its burst.

Sample input:

```
4 3
5 10 3 8
```

Sample output:

```
3 1 4 2
```

## Idea

Each job finishes on its own numbered visit, like shoppers at one counter who each need a known number of turns.

The method counts visits with a ceiling division and sorts by visit count, then by arrival index. Counting costs one division per process. Simulating every quantum costs up to 10^9 steps for one process when Q is 1.

Takeaway: count the visits instead of replaying them.

## Why It Works

1. A process with burst T and quantum Q needs ceil(T / Q) visits to the CPU.
2. On its last visit the remaining time fits inside one quantum, so it finishes there.
3. Each unfinished visit returns the process to the back of the queue.
4. After every full round, the surviving processes are still in arrival order.
5. Therefore processes with the same visit count finish in increasing ID order.
6. Sorting by (turn_count, process_id) reproduces the exact completion order.

| term | meaning |
|---|---|
| `process_count` | how many processes arrive |
| `quantum` | the fixed time slice Q |
| `burst` | the total CPU time T_i of one process |
| `turn_count` | ceil of burst divided by quantum |
| `processes` | records of visit count and process ID |

Every process becomes one record with two comparable fields.

For the sample, Q is 3 and the bursts are 5 10 3 8. The visit counts are 2 4 1 3. Sorting by visit count, then ID, gives process 3, then 1, then 4, then 2.

The numerator `burst + quantum - 1` is kept in `long long`, so large values stay exact. Ties are broken by ID, which matches the queue order.

## Code

**Input, output, and comparator.** The scanner parses burst times and `compare_records` orders `(turn_count, process_id)` pairs.

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
```

The comparator preserves queue order by breaking visit ties on `process_id`.

**Record build and emission.** Each burst converts to ceiling division turns, sorts with `qsort`, and prints one ID line.

```c
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
```

One `flush_out` call writes all sorted IDs cleanly.

## Complexity

Counting is linear, and sorting orders all N records.

| phase | time | space |
|---|---|---|
| input read | one pass over N bursts | one input string |
| visit count | one division per process | N records |
| sort | N comparisons at each level | constant extra |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

Replaying every quantum slice costs O(sum of T_i divided by Q) steps.

Takeaway: a visit count and one sort replace the whole simulation.
