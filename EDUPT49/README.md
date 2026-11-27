# EDUPT49 — O Pátio de Manobras e o Trem de Carga (SPOJ)

<https://www.spoj.com/problems/EDUPT49/>

## Problem

Cars arrive in a fixed order and must leave in a desired order, using one siding that acts as a stack. Decide whether the reordering is possible, and print the moves that achieve it.

Input starts with N, followed by the arrival order and the desired order, each holding N distinct car numbers. A PUSH moves the next arriving car onto the stack. A POP moves the top car onto the departing train. Output one move per line, or the word IMPOSSIVEL when no sequence works.

The counts are moderate.

| item | bound |
|---|---|
| car count N | 1 to 1000 |
| car numbers | distinct, from 1 to N |
| judge limit | 1000 ms, 1536 MB |

Every car must be pushed before it can leave the siding, even if it leaves immediately.

Sample input:

```
5
1 2 3 4 5
3 2 5 4 1
```

Sample output:

```
PUSH
PUSH
PUSH
POP
POP
PUSH
PUSH
POP
POP
POP
```

## Idea

Push cars until the wanted one reaches the top, then pop it, like pulling plates off a stack exactly when a waiter asks for them.

The real algorithm is a greedy stack simulation with one arrival cursor. Each car is pushed once and popped once, so the scan is linear. Trying all push and pop sequences would branch exponentially. The takeaway is that the next wanted car forces the next move.

## Why It Works

1. The stack top is the only car that can leave at any moment.
2. If the top is not the wanted car, more arrivals must be pushed.
3. Pushing stops as soon as the wanted car reaches the top.
4. That car is then popped, and the desired order advances.
5. If arrivals run out before the top matches, no valid sequence exists.

| term | meaning |
|---|---|
| `maneuver_stack` | cars currently waiting on the siding |
| `next_car` | position of the next car in the arrival line |
| `operation_text` | collected move lines, kept until success is known |
| `desired` | target departure permutation |

The greedy choice is forced, so the move sequence is unique when it exists.

For the sample the wanted cars are 3, 2, 5, 4, 1. Three pushes place 3 on top, and two pops release 3 then 2. Two more pushes place 5 on top, and three pops release 5, 4 and 1.

For arrival 1, 2, 3, 4 and target 4, 2, 3, 1, the first pop releases 4. The top is then 3 while the next wanted car is 2. No arrivals remain, so the answer is IMPOSSIVEL.

Failed runs discard `operation_text` and print only the failure word.

## Code

**Input, scanner, and buffered output.** The stream loads once into `indata` and `put_mem` buffers output blocks.

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

`read_all` expands the buffer dynamically and NUL-terminates `indata`.

**Greedy stack simulation.** Pushes advance until `maneuver_stack` exposes `desired[d]`, then emit the move transcript or `IMPOSSIVEL`.

```c
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
```

Only valid runs emit `operation_text`, followed by a single flush.

## Complexity

Each car is pushed once and popped at most once.

| phase | time | space |
|---|---|---|
| input read | one pass over both orders | one input string |
| stack scan | one push per car and one pop per car | two order arrays and a stack |
| output | up to two lines per car | one move buffer |

The counts below describe the whole run.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

Enumerating all push and pop choices would grow exponentially, while the forced greedy move settles each step in constant time.
