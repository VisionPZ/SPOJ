#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    node_count = tokens[0]
    pair_count = tokens[1]
    edges = [(tokens[2 + 2 * index], tokens[3 + 2 * index]) for index in range(pair_count)]
    neighbors = {}
    for left, right in edges:
        neighbors.setdefault(left, set()).add(right)
        neighbors.setdefault(right, set()).add(left)
    seen = set()
    components = 0
    for start in neighbors:
        if start in seen:
            continue
        components += 1
        seen.add(start)
        stack = [start]
        while stack:
            node = stack.pop()
            for nxt in neighbors[node]:
                if nxt not in seen:
                    seen.add(nxt)
                    stack.append(nxt)
    answer = components + (node_count - len(seen))
    return str(answer) + "\n"


SAMPLE = """9 5
3 1
6 1
7 6
2 7
8 9
"""
SAMPLE_OUT = "4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1 1\n") == "1\n"
assert oracle("5 1\n2 4\n") == "4\n"
assert oracle("1000000000 2\n7 8\n8 9\n") == "999999998\n"
assert oracle("4 2\n1 2\n3 4\n") == "2\n"


def write(name, node_count, edges):
    lines = [f"{node_count} {len(edges)}"]
    lines.extend(f"{left} {right}" for left, right in edges)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 5, [(1, 5)])
    write("3_wide", 10**9, [(index, index + 1) for index in range(1, 100)])
    rng = random.Random(20261127)
    edges = set()
    while len(edges) < 200:
        left = rng.randint(1, 1000)
        right = rng.randint(1, 1000)
        if left != right:
            edges.add((left, right))
    write("4_random", 1000, sorted(edges))
    edges = set()
    while len(edges) < 100000:
        left = rng.randint(1, 10**9)
        right = rng.randint(1, 10**9)
        if left != right:
            edges.add((left, right))
    write("5_io", 10**9, sorted(edges))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 9, [(3, 1), (6, 1), (7, 6), (2, 7), (8, 9)])
build()
