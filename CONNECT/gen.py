#!/usr/bin/env python3
import random
from heapq import heappop, heappush
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    pos = 0
    case_count = int(tokens[pos]); pos += 1
    cases = []
    for _ in range(case_count):
        n = int(tokens[pos]); pos += 1
        m = int(tokens[pos]); pos += 1
        edges = []
        for _ in range(m):
            u = int(tokens[pos]) - 1; pos += 1
            v = int(tokens[pos]) - 1; pos += 1
            w = int(tokens[pos]); pos += 1
            edges.append((u, v, w))
        q = int(tokens[pos]); pos += 1
        queries = []
        for _ in range(q):
            c = int(tokens[pos]) - 1; pos += 1
            d = int(tokens[pos]) - 1; pos += 1
            k = int(tokens[pos]); pos += 1
            queries.append((c, d, k))
        cases.append((n, edges, queries))
    return cases


def insert_best(lst, value, limit):
    if len(lst) >= limit and value >= lst[-1]:
        return
    pos = 0
    while pos < len(lst) and lst[pos] < value:
        pos += 1
    lst.insert(pos, value)
    if len(lst) > limit:
        lst.pop()


def oracle_bellman(n, edges, queries):
    need = {}
    for c, d, k in queries:
        need[c] = max(need.get(c, 0), k)
    table = {}
    for source, kmax in need.items():
        all_labels = [[] for _ in range(n)]
        frontier = [[] for _ in range(n)]
        frontier[source] = [0]
        all_labels[source] = [0]
        rounds = kmax * n + 5
        for _ in range(rounds):
            new_frontier = [[] for _ in range(n)]
            for u, v, w in edges:
                for value in frontier[u]:
                    insert_best(new_frontier[v], value + w, kmax)
            for v in range(n):
                for value in new_frontier[v]:
                    insert_best(all_labels[v], value, kmax + 1)
            frontier = new_frontier
            if 0 in all_labels[source]:
                all_labels[source].remove(0)
        table[source] = all_labels
    return [str(table[c][d][k - 1]) if len(table[c][d]) >= k else "-1"
            for c, d, k in queries]


def oracle_heap(n, edges, queries):
    adj = [[] for _ in range(n)]
    for u, v, w in edges:
        adj[u].append((v, w))
    need = {}
    for c, d, k in queries:
        need[c] = max(need.get(c, 0), k)
    table = {}
    for source, kmax in need.items():
        labels = [[] for _ in range(n)]
        heap = [(0, source)]
        while heap:
            dist, u = heappop(heap)
            if dist > 0:
                if len(labels[u]) >= kmax and dist >= labels[u][-1]:
                    continue
                pos = 0
                while pos < len(labels[u]) and labels[u][pos] < dist:
                    pos += 1
                labels[u].insert(pos, dist)
            for v, w in adj[u]:
                candidate = dist + w
                if len(labels[v]) < kmax or candidate < labels[v][-1]:
                    heappush(heap, (candidate, v))
        table[source] = labels
    return [str(table[c][d][k - 1]) if len(table[c][d]) >= k else "-1"
            for c, d, k in queries]


def render(cases):
    lines = [str(len(cases))]
    for n, edges, queries in cases:
        lines.append("")
        lines.append(f"{n} {len(edges)}")
        for u, v, w in edges:
            lines.append(f"{u + 1} {v + 1} {w}")
        lines.append(str(len(queries)))
        for c, d, k in queries:
            lines.append(f"{c + 1} {d + 1} {k}")
    return "\n".join(lines) + "\n"


def oracle(cases):
    blocks = []
    for n, edges, queries in cases:
        if n <= 10 and len(edges) <= 100:
            blocks.append("\n".join(oracle_bellman(n, edges, queries)))
        else:
            blocks.append("\n".join(oracle_heap(n, edges, queries)))
    return "\n\n".join(blocks) + "\n"


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


SAMPLE_TEXT = """1

5 5
1 2 3
2 3 2
3 2 1
1 3 10
1 4 1
8
1 3 1
1 3 2
1 3 3
1 4 2
2 5 1
2 2 1
2 2 2
1 1 2
"""
SAMPLE_OUT = """5
8
10
-1
-1
3
6
-1
"""
SAMPLE_CASES = parse(SAMPLE_TEXT)

assert oracle_bellman(*SAMPLE_CASES[0]) == SAMPLE_OUT.rstrip("\n").split("\n")
assert oracle_heap(*SAMPLE_CASES[0]) == SAMPLE_OUT.rstrip("\n").split("\n")
assert render(SAMPLE_CASES) == SAMPLE_TEXT

two_node = (2, [(0, 1, 7)], [(0, 1, 1), (0, 1, 2), (1, 0, 1), (0, 0, 1)])
assert oracle_bellman(*two_node) == ["7", "-1", "-1", "-1"]
assert oracle_heap(*two_node) == ["7", "-1", "-1", "-1"]

loop_case = (2, [(0, 1, 500), (1, 0, 500)], [(0, 0, 1), (0, 0, 2), (0, 1, 2)])
assert oracle_bellman(*loop_case) == ["1000", "2000", "1500"]
assert oracle_heap(*loop_case) == ["1000", "2000", "1500"]

check_rng = random.Random(101)
for _ in range(120):
    n = check_rng.randint(1, 6)
    pairs = [(a, b) for a in range(n) for b in range(n) if a != b]
    check_rng.shuffle(pairs)
    edges = [(a, b, check_rng.randint(1, 6))
             for a, b in pairs[:check_rng.randint(0, len(pairs))]]
    queries = [(check_rng.randrange(n), check_rng.randrange(n),
                check_rng.randint(1, 6)) for _ in range(12)]
    assert oracle_bellman(n, edges, queries) == oracle_heap(n, edges, queries)


def build():
    write("1_sample", SAMPLE_CASES)

    edge_cases = [
        (1, [], [(0, 0, 1), (0, 0, 100)]),
        (2, [(0, 1, 1)], [(0, 1, 1), (0, 1, 2), (1, 0, 1), (0, 0, 1)]),
        (2, [(0, 1, 500), (1, 0, 500)],
         [(0, 0, 1), (0, 0, 2), (0, 1, 1), (0, 1, 2), (1, 1, 100)]),
        (5, [], [(0, 4, 1), (4, 4, 5)]),
        (3, [(0, 1, 1), (1, 2, 1), (2, 0, 1)],
         [(0, 0, 1), (0, 2, 1), (0, 2, 2), (2, 0, 100), (1, 0, 3)]),
    ]
    write("2_edges", edge_cases)

    wide_rng = random.Random(707)
    all_pairs = [(a, b) for a in range(100) for b in range(100) if a != b]
    dense_edges = [(a, b, wide_rng.randint(1, 500)) for a, b in all_pairs]
    dense_queries = [(wide_rng.randrange(100), wide_rng.randrange(100),
                      wide_rng.randint(1, 5)) for _ in range(1000)]
    sparse_pairs = list(all_pairs)
    wide_rng.shuffle(sparse_pairs)
    sparse_edges = [(a, b, wide_rng.randint(1, 500))
                    for a, b in sparse_pairs[:300]]
    sparse_queries = [(wide_rng.randrange(100), wide_rng.randrange(100),
                       wide_rng.randint(1, 100)) for _ in range(10000)]
    write("3_wide", [(100, dense_edges, dense_queries),
                     (100, sparse_edges, sparse_queries)])

    random_rng = random.Random(2026)
    random_cases = []
    for _ in range(6):
        n = random_rng.randint(2, 7)
        pairs = [(a, b) for a in range(n) for b in range(n) if a != b]
        random_rng.shuffle(pairs)
        edges = [(a, b, random_rng.randint(1, 500))
                 for a, b in pairs[:random_rng.randint(0, len(pairs))]]
        queries = [(random_rng.randrange(n), random_rng.randrange(n),
                    random_rng.randint(1, 8))
                   for _ in range(random_rng.randint(50, 200))]
        random_cases.append((n, edges, queries))
    write("4_random", random_cases)

    io_rng = random.Random(31337)
    io_cases = []
    for case_index in range(15):
        n = 4
        pairs = [(a, b) for a in range(n) for b in range(n) if a != b]
        io_rng.shuffle(pairs)
        edges = [(a, b, io_rng.randint(480, 500))
                 for a, b in pairs[:io_rng.randint(8, len(pairs))]]
        queries = [(io_rng.randrange(n), io_rng.randrange(n), io_rng.randint(1, 3))
                   for _ in range(10000)]
        io_cases.append((n, edges, queries))
    write("5_io", io_cases)

    stress_rng = random.Random(9001)
    stress_edges = [(a, b, stress_rng.randint(1, 500)) for a, b in all_pairs]
    stress_queries = [(stress_rng.randrange(100), stress_rng.randrange(100), 100)
                      for _ in range(10000)]
    Path("/tmp/CONNECT_big.txt").write_text(render([(100, stress_edges, stress_queries)]))
    io_big_cases = []
    for case_index in range(15):
        io_edges = [(a, b, io_rng.randint(1, 500))
                    for a in range(20) for b in range(20) if a != b
                    if io_rng.random() < 0.25]
        io_queries = [(io_rng.randrange(20), io_rng.randrange(20), 3)
                      for _ in range(10000)]
        io_big_cases.append((20, io_edges, io_queries))
    Path("/tmp/CONNECT_io_big.txt").write_text(render(io_big_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
