#!/usr/bin/env python3
import itertools
import random
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "5\n"
    "0 0\n"
    "1 0\n"
    "3 3 (0,1) (0,2) (1,2)\n"
    "2 0\n"
    "5 7 (0,1) (0,2) (1,3) (1,2) (1,4) (2,3) (3,4)\n"
)
SAMPLE_OUTPUT = "0\n1\n3\n0\n2\n"


def is_connected(vertices, adj):
    remaining = set(vertices)
    if len(remaining) <= 1:
        return True
    start = next(iter(remaining))
    seen = {start}
    stack = [start]
    while stack:
        current = stack.pop()
        for neighbor in remaining:
            if neighbor not in seen and adj[current][neighbor]:
                seen.add(neighbor)
                stack.append(neighbor)
    return len(seen) == len(remaining)


def brute(n, edges):
    adj = [[False] * n for _ in range(n)]
    for u, v in edges:
        adj[u][v] = True
        adj[v][u] = True
    if not is_connected(range(n), adj):
        return 0
    for removed_count in range(1, n):
        for removed in itertools.combinations(range(n), removed_count):
            removed_set = set(removed)
            remaining = [v for v in range(n) if v not in removed_set]
            if not is_connected(remaining, adj):
                return removed_count
    return n


def complete(n):
    return [(u, v) for u in range(n) for v in range(u + 1, n)]


def cycle(n):
    return [(i, (i + 1) % n) for i in range(n)]


def star(n):
    return [(0, v) for v in range(1, n)]


def path(n):
    return [(i, i + 1) for i in range(n - 1)]


def bipartite(left_size, right_size):
    return [(u, left_size + v) for u in range(left_size) for v in range(right_size)]


def bridge_cliques(side_size, bridge_count):
    edges = []
    for u in range(side_size):
        for v in range(u + 1, side_size):
            edges.append((u, v))
        left = side_size + u
        for v in range(u + 1, side_size):
            edges.append((left, side_size + v))
    for index in range(bridge_count):
        edges.append((index, side_size + index))
    return edges


assert brute(0, []) == 0
assert brute(1, []) == 1
assert brute(3, [(0, 1), (0, 2), (1, 2)]) == 3
assert brute(2, []) == 0
assert brute(5, [(0, 1), (0, 2), (1, 3), (1, 2), (1, 4), (2, 3), (3, 4)]) == 2
assert brute(5, cycle(5)) == 2
assert brute(6, bipartite(3, 3)) == 3
assert brute(8, bridge_cliques(4, 2)) == 2


def case_text(n, edges):
    pair_text = " ".join(f"({u},{v})" for u, v in edges)
    if pair_text:
        return f"{n} {len(edges)} {pair_text}\n"
    return f"{n} {len(edges)}\n"


def write(name, specs):
    input_text = str(len(specs)) + "\n" + "".join(case_text(n, e) for n, e, _ in specs)
    answers = [str(expected if expected is not None else brute(n, e)) for n, e, expected in specs]
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


def cross_check():
    binary = ROOT / "build" / "solution"
    if not binary.exists():
        return
    rng = random.Random(424242)
    cases = []
    for _ in range(250):
        n = rng.randint(0, 7)
        edges = [(u, v) for u in range(n) for v in range(u + 1, n) if rng.random() < 0.45]
        cases.append((n, edges))
    payload = str(len(cases)) + "\n" + "".join(case_text(n, e) for n, e in cases)
    try:
        result = subprocess.run([str(binary)], input=payload.encode(), stdout=subprocess.PIPE, timeout=10)
    except subprocess.TimeoutExpired:
        return
    got = result.stdout.decode().split()
    want = [str(brute(n, e)) for n, e in cases]
    assert got == want, "oracle disagrees with solution on random graphs"


def build():
    write("1_sample", [
        (0, [], 0),
        (1, [], 1),
        (3, complete(3), 3),
        (2, [], 0),
        (5, [(0, 1), (0, 2), (1, 3), (1, 2), (1, 4), (2, 3), (3, 4)], 2),
    ])
    sample_in = (ROOT / "in" / "1_sample.txt").read_text()
    sample_out = (ROOT / "out" / "1_sample.out").read_text()
    assert sample_in == SAMPLE_INPUT
    assert sample_out == SAMPLE_OUTPUT

    write("2_edges", [
        (0, [], 0),
        (1, [], 1),
        (2, [], 0),
        (2, [(0, 1)], 2),
        (3, [(0, 1)], 0),
        (3, path(3), 1),
        (3, complete(3), 3),
        (4, star(4), 1),
        (4, cycle(4), 2),
        (4, complete(4), 4),
        (5, [(0, 1), (2, 3)], 0),
        (5, cycle(5), 2),
        (5, bipartite(2, 3), 2),
        (6, bridge_cliques(3, 3), 3),
    ])

    large_specs = [
        (50, complete(50), 50),
        (50, cycle(50), 2),
        (50, star(50), 1),
        (50, path(50), 1),
        (50, [], 0),
        (50, bipartite(25, 25), 25),
        (50, bridge_cliques(25, 1), 1),
        (50, bridge_cliques(25, 4), 4),
        (50, complete(25), 0),
        (40, bridge_cliques(20, 10), 10),
    ]
    rng = random.Random(20261125)
    for _ in range(10):
        n = rng.randint(5, 10)
        edges = [(u, v) for u in range(n) for v in range(u + 1, n) if rng.random() < 0.4]
        large_specs.append((n, edges, None))
    write("3_wide", large_specs)

    rng = random.Random(20261126)
    random_specs = []
    for _ in range(20):
        n = rng.randint(2, 9)
        density = rng.uniform(0.0, 1.0)
        edges = [(u, v) for u in range(n) for v in range(u + 1, n) if rng.random() < density]
        random_specs.append((n, edges, None))
    write("4_random", random_specs)

    rng = random.Random(20261127)
    io_specs = [
        (50, complete(50), 50),
        (50, cycle(50), 2),
        (50, star(50), 1),
        (20, bipartite(10, 10), 10),
        (50, bridge_cliques(25, 7), 7),
    ]
    for _ in range(15):
        n = 10
        edges = [(u, v) for u in range(n) for v in range(u + 1, n) if rng.random() < 0.55]
        io_specs.append((n, edges, None))
    write("5_io", io_specs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
cross_check()
