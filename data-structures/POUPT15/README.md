# POUPT15 — É uma AVL? (SPOJ)

<https://www.spoj.com/problems/POUPT15/>

## Problem

Insert the given keys into an ordinary binary search tree, then decide whether every node has balanced subtree heights. Print `sim` for a balanced tree and `nao` for an unbalanced tree.

The first line holds the test case count. Each case holds positive keys in the range 0 to 64000, read until the sentinel -1. Print one answer line per case.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| keys | 0 to 64000, terminated by -1 |
| judge limit | 5000 ms, 1536 MB |

The sentinel is not part of the tree.

Sample input:

```
3
40 30 25 50 35 60 45 -1
25 36 20 22 30 40 38 28 10 5 12 48 -1
25 36 20 22 30 40 38 28 10 5 12 1 8 15 48 50 45   -1
```

Sample output:

```
sim
sim
nao
```

## Idea

Treat each node like a shelf that must hold two side stacks of nearly equal height. Build the tree by plain insertion, then measure both subtrees at every node. A node fails when its Child heights differ by more than one. A single bottom-up pass computes all heights, because parents are always created before their children.

The real algorithm is a bottom-up height computation over an array of nodes. Each node costs constant work, so the whole case costs linear time in the number of keys. Rescanning the tree from the root for each node would cost quadratic time instead. The takeaway is that creation order gives a ready-made bottom-up order.

## Why It Works

1. Insertion into a binary search tree places each key at one new leaf.
2. A parent node always gets a smaller array index than its children.
3. Scanning node indices in reverse therefore visits children before parents.
4. A missing child contributes height zero, and a present child contributes its stored height.
5. An AVL tree requires the two Child heights to differ by at most one at every node.

| term | meaning |
|---|---|
| `node_keys` | key stored at each tree node |
| `left_child` | index of the left child, or -1 when absent |
| `right_child` | index of the right child, or -1 when absent |
| `node_height` | height of the subtree rooted at each node |
| `balanced` | zero once any node fails the height test |

The reverse scan reads each stored child height exactly once.

For the first sample the root 40 has a left subtree of height 3 and a right subtree of height 2. The difference is one, so that node passes. Every other node also passes, which yields `sim`.

## Code

**Input, scanner, and vector buffer.** `read_all` loads all tokens and `IntVec` collects each case until `-1`.

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

Signed parsing recognizes the `-1` sentinel terminating every tree sequence.

**Tree construction and bottom-up height check.** Each node inserts into the array tree, then reverse traversal checks child height differences.

```c
int main(void) {
    read_all();
    int case_count = (int)next_int();
    for (int case_index = 0; case_index < case_count; case_index++) {
        IntVec node_keys = {NULL, 0, 0};
        for (;;) {
            long long scanned = next_int();
            if (scanned == -1) {
                break;
            }
            iv_push(&node_keys, (int)scanned);
        }
        size_t node_total = node_keys.len;
        int *left_child = (int *)malloc(node_total > 0 ? node_total * sizeof(int) : 1);
        int *right_child = (int *)malloc(node_total > 0 ? node_total * sizeof(int) : 1);
        int *node_height = (int *)malloc(node_total > 0 ? node_total * sizeof(int) : 1);
        int root_node = -1;
        for (size_t new_node = 0; new_node < node_total; new_node++) {
            left_child[new_node] = -1;
            right_child[new_node] = -1;
            int key = node_keys.data[new_node];
            if (root_node == -1) {
                root_node = (int)new_node;
                continue;
            }
            int current = root_node;
            for (;;) {
                if (key < node_keys.data[current]) {
                    if (left_child[current] == -1) {
                        left_child[current] = (int)new_node;
                        break;
                    }
                    current = left_child[current];
                } else {
                    if (right_child[current] == -1) {
                        right_child[current] = (int)new_node;
                        break;
                    }
                    current = right_child[current];
                }
            }
        }
        int balanced = 1;
        for (size_t walk = node_total; walk-- > 0;) {
            int left_height = left_child[walk] == -1 ? 0 : node_height[left_child[walk]];
            int right_height = right_child[walk] == -1 ? 0 : node_height[right_child[walk]];
            node_height[walk] = 1 + (left_height > right_height ? left_height : right_height);
            if (left_height - right_height > 1 || right_height - left_height > 1) {
                balanced = 0;
            }
        }
        if (balanced) {
            put_mem("sim\n", 4);
        } else {
            put_mem("nao\n", 4);
        }
        free(left_child);
        free(right_child);
        free(node_height);
        free(node_keys.data);
    }
    flush_out();
    return 0;
}
```

Checking `left_height` and `right_height` in reverse order verifies the AVL property in linear time.

## Complexity

Each key walks down the tree once, and each node is visited once during the height pass.

| phase | time | space |
|---|---|---|
| input read | one pass over all keys | one input string |
| tree build | one root-to-leaf walk per key | three node arrays |
| height pass | one visit per node | one height array |

| measure | Big O |
|---|---|
| time | O(k) per case, for k keys |
| space | O(k) per case |

Checking balance by rescanning subtrees from every node would cost O(k^2) time.
The reverse height pass keeps each case linear.
