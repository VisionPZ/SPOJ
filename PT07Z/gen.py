#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    vals = [int(tok) for tok in text.split()]
    n = vals[0]
    if n <= 1:
        return "0\n"
    adj = [[] for _ in range(n + 1)]
    for i in range(n - 1):
        u = vals[1 + 2 * i]
        v = vals[2 + 2 * i]
        adj[u].append(v)
        adj[v].append(u)
    best = 0
    parent = [0] * (n + 1)
    order = []
    stack = [1]
    while stack:
        cur = stack.pop()
        order.append(cur)
        for nxt in adj[cur]:
            if nxt != parent[cur]:
                parent[nxt] = cur
                stack.append(nxt)
    down1 = [0] * (n + 1)
    down2 = [0] * (n + 1)
    for cur in reversed(order):
        d1 = 0
        d2 = 0
        for nxt in adj[cur]:
            if nxt == parent[cur]:
                continue
            cand = down1[nxt] + 1
            if cand >= d1:
                d2 = d1
                d1 = cand
            elif cand > d2:
                d2 = cand
        down1[cur] = d1
        down2[cur] = d2
        if d1 + d2 > best:
            best = d1 + d2
    return f"{best}\n"


assert oracle("3\n1 2\n2 3\n") == "2\n"
assert oracle("1\n") == "0\n"
assert oracle("5\n1 2\n1 3\n1 4\n1 5\n") == "2\n"
assert oracle("6\n1 2\n2 3\n3 4\n2 5\n5 6\n") == "4\n"


def write_case(name, n, edges):
    text = f"{n}\n" + "".join(f"{u} {v}\n" for u, v in edges)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", 3, [(1, 2), (2, 3)])
write_case("2_edges", 1, [])
write_case("3_wide", 10000, [(i, i + 1) for i in range(1, 10000)])
rng = random.Random(708)
write_case("4_random", 10000, [(rng.randint(1, v - 1), v) for v in range(2, 10001)])
write_case("5_io", 10000, [(1, v) for v in range(2, 5001)] + [(i, i + 1) for i in range(5000, 10000)])
