#!/usr/bin/env python3
from collections import deque
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    vals = [int(tok) for tok in text.split()]
    n, m = vals[0], vals[1]
    if m != n - 1:
        return "NO\n"
    adj = [[] for _ in range(n + 1)]
    for i in range(m):
        u = vals[2 + 2 * i]
        v = vals[3 + 2 * i]
        if u == v:
            return "NO\n"
        adj[u].append(v)
        adj[v].append(u)
    seen = [False] * (n + 1)
    q = deque([1])
    seen[1] = True
    count = 0
    while q:
        cur = q.popleft()
        count += 1
        for nxt in adj[cur]:
            if not seen[nxt]:
                seen[nxt] = True
                q.append(nxt)
    return "YES\n" if count == n else "NO\n"


assert oracle("3 2\n1 2\n2 3\n") == "YES\n"
assert oracle("3 3\n1 2\n2 3\n1 3\n") == "NO\n"
assert oracle("4 3\n1 2\n3 4\n3 4\n") == "NO\n"
assert oracle("1 0\n") == "YES\n"


def write_case(name, n, edges):
    text = f"{n} {len(edges)}\n" + "".join(f"{u} {v}\n" for u, v in edges)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", 3, [(1, 2), (2, 3)])
write_case("2_edges", 4, [(1, 2), (1, 2), (3, 4)])
write_case("3_wide", 10000, [(i, i + 1) for i in range(1, 10000)])
rng = random.Random(707)
tree_edges = [(rng.randint(1, v - 1), v) for v in range(2, 10001)]
write_case("4_random", 10000, tree_edges)
cycle_edges = [(rng.randint(1, 10000), rng.randint(1, 10000)) for _ in range(20000)]
write_case("5_io", 10000, cycle_edges)
