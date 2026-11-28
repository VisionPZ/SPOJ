#!/usr/bin/env python3
from collections import deque
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    vals = [int(tok) for tok in text.split()]
    t = vals[0]
    pos = 1
    out = []
    for idx in range(1, t + 1):
        n = vals[pos]
        m = vals[pos + 1]
        pos += 2
        adj = [[] for _ in range(n + 1)]
        for _ in range(m):
            u, v = vals[pos], vals[pos + 1]
            pos += 2
            adj[u].append(v)
            adj[v].append(u)
        color = [-1] * (n + 1)
        bad = False
        for start in range(1, n + 1):
            if color[start] != -1:
                continue
            color[start] = 0
            q = deque([start])
            while q and not bad:
                cur = q.popleft()
                for nxt in adj[cur]:
                    if color[nxt] == -1:
                        color[nxt] = color[cur] ^ 1
                        q.append(nxt)
                    elif color[nxt] == color[cur]:
                        bad = True
                        break
            if bad:
                break
        out.append(f"Scenario #{idx}:")
        out.append("Suspicious bugs found!" if bad else "No suspicious bugs found!")
    return "\n".join(out) + "\n"


SAMPLE = "2\n3 3\n1 2\n2 3\n1 3\n4 2\n1 2\n3 4\n"
SAMPLE_OUT = "Scenario #1:\nSuspicious bugs found!\nScenario #2:\nNo suspicious bugs found!\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 0\n") == "Scenario #1:\nNo suspicious bugs found!\n"
assert oracle("1\n4 4\n1 2\n2 3\n3 4\n4 1\n") == "Scenario #1:\nNo suspicious bugs found!\n"


def write_case(name, scenarios):
    parts = [f"{len(scenarios)}\n"]
    for n, edges in scenarios:
        parts.append(f"{n} {len(edges)}\n")
        parts.extend(f"{u} {v}\n" for u, v in edges)
    text = "".join(parts)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [(3, [(1, 2), (2, 3), (1, 3)]), (4, [(1, 2), (3, 4)])])
write_case("2_edges", [(1, []), (2, [(1, 2)]), (4, [(1, 2), (2, 3), (3, 4), (4, 1)]), (5, [(1, 2), (2, 3), (3, 4), (4, 5), (5, 1)])])
write_case("3_wide", [(2000, [(i, i + 1) for i in range(1, 2000)])])

rng = random.Random(3030)
rand_scens = []
for s in range(12):
    n = 150
    edges = []
    if s % 2 == 0:
        side = [rng.randint(0, 1) for _ in range(n + 1)]
        for _ in range(400):
            u = rng.randint(1, n)
            v = rng.randint(1, n)
            if side[u] != side[v]:
                edges.append((u, v))
    else:
        for _ in range(300):
            u = rng.randint(1, n)
            v = rng.randint(1, n)
            if u != v:
                edges.append((u, v))
    rand_scens.append((n, edges))
write_case("4_random", rand_scens)

big_edges = [(i, 1000 + (i % 1000) + 1) for i in range(1, 1001)] * 300
write_case("5_io", [(2000, big_edges[:300000])])
