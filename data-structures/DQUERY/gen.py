#!/usr/bin/env python3
import math
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle_mo(text):
    vals = [int(tok) for tok in text.split()]
    n = vals[0]
    arr = [0] + vals[1 : 1 + n]
    q = vals[1 + n]
    queries = []
    pos = 2 + n
    for idx in range(q):
        l = vals[pos]
        r = vals[pos + 1]
        pos += 2
        queries.append((l, r, idx))
    block = max(1, int(math.sqrt(n)))
    queries.sort(key=lambda item: (item[0] // block, item[1] if (item[0] // block) % 2 == 0 else -item[1]))
    freq = [0] * 1000001
    distinct = 0
    cur_l, cur_r = 1, 0
    ans = [0] * q
    for l, r, idx in queries:
        while cur_r < r:
            cur_r += 1
            v = arr[cur_r]
            if freq[v] == 0:
                distinct += 1
            freq[v] += 1
        while cur_l > l:
            cur_l -= 1
            v = arr[cur_l]
            if freq[v] == 0:
                distinct += 1
            freq[v] += 1
        while cur_r > r:
            v = arr[cur_r]
            freq[v] -= 1
            if freq[v] == 0:
                distinct -= 1
            cur_r -= 1
        while cur_l < l:
            v = arr[cur_l]
            freq[v] -= 1
            if freq[v] == 0:
                distinct -= 1
            cur_l += 1
        ans[idx] = distinct
    return "\n".join(str(x) for x in ans) + "\n"


def oracle_brute(text):
    vals = [int(tok) for tok in text.split()]
    n = vals[0]
    arr = [0] + vals[1 : 1 + n]
    q = vals[1 + n]
    out = []
    pos = 2 + n
    for _ in range(q):
        l, r = vals[pos], vals[pos + 1]
        pos += 2
        out.append(str(len(set(arr[l : r + 1]))))
    return "\n".join(out) + "\n"


SAMPLE = "5\n1 1 2 1 3\n3\n1 5\n2 4\n3 5\n"
assert oracle_mo(SAMPLE) == "3\n2\n3\n"
assert oracle_brute(SAMPLE) == oracle_mo(SAMPLE)
assert oracle_brute("1\n42\n1\n1 1\n") == oracle_mo("1\n42\n1\n1 1\n")


def write_case(name, arr, queries):
    text = (
        f"{len(arr)}\n"
        + " ".join(str(x) for x in arr)
        + f"\n{len(queries)}\n"
        + "".join(f"{l} {r}\n" for l, r in queries)
    )
    (ROOT / "in" / f"{name}.txt").write_text(text)
    if len(queries) <= 500:
        expected = oracle_brute(text)
        assert expected == oracle_mo(text)
    else:
        expected = oracle_mo(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [1, 1, 2, 1, 3], [(1, 5), (2, 4), (3, 5)])
write_case("2_edges", [5, 5, 5, 5, 5], [(1, 1), (5, 5), (1, 5), (2, 4)])
write_case("3_wide", list(range(1, 301)), [(1, 300), (1, 1), (300, 300), (100, 200)])

rng = random.Random(2025)
arr_rand = [rng.randint(1, 1000) for _ in range(400)]
q_rand = []
for _ in range(400):
    a = rng.randint(1, 400)
    b = rng.randint(a, 400)
    q_rand.append((a, b))
write_case("4_random", arr_rand, q_rand)

arr_max = [rng.randint(1, 1000000) for _ in range(30000)]
q_max = []
for idx in range(200000):
    a = (idx % 15000) + 1
    b = min(30000, a + 50 + (idx % 1000))
    q_max.append((a, b))
write_case("5_io", arr_max, q_max)
