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
