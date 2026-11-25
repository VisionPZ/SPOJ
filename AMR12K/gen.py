#!/usr/bin/env python3
import itertools
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """2
2
1 2
1
1
2
1 2
1
2
"""
SAMPLE_OUT = """0.5
0
"""


def parent_map(orc_count, edges):
    neighbours = [[] for _ in range(orc_count + 1)]
    for first, second in edges:
        neighbours[first].append(second)
        neighbours[second].append(first)
    parent = [0] * (orc_count + 1)
    visited = [False] * (orc_count + 1)
    visited[1] = True
    queue = deque([1])
    while queue:
        orc = queue.popleft()
        for neighbour in neighbours[orc]:
            if not visited[neighbour]:
                visited[neighbour] = True
                parent[neighbour] = orc
                queue.append(neighbour)
    return parent


def brute_force(orc_count, edges, dead):
    parent = parent_map(orc_count, edges)
    dead_set = set(dead)
    total_saved = 0.0
    orderings = list(itertools.permutations(range(1, orc_count + 1)))
    for order in orderings:
        marked = set()
        saved = 0
        for orc in order:
            ancestor = parent[orc]
            skipped = False
            while ancestor:
                if ancestor in marked:
                    skipped = True
                    break
                ancestor = parent[ancestor]
            if skipped:
                saved += 1
            elif orc in dead_set:
                marked.add(orc)
        total_saved += saved
    return total_saved / len(orderings)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    test_count = tokens[pos]
    pos += 1
    lines = []
    for _ in range(test_count):
        orc_count = tokens[pos]
        pos += 1
        edges = []
        children = [[] for _ in range(orc_count + 1)]
        for _ in range(orc_count - 1):
            first = tokens[pos]
            second = tokens[pos + 1]
            pos += 2
            edges.append((first, second))
            children[first].append(second)
            children[second].append(first)
        dead_count = tokens[pos]
        pos += 1
        dead = set()
        for _ in range(dead_count):
            dead.add(tokens[pos])
            pos += 1
        is_dead = [False] * (orc_count + 1)
        for orc in dead:
            is_dead[orc] = True
        dead_ancestors = [0] * (orc_count + 1)
        visited = [False] * (orc_count + 1)
        visited[1] = True
        queue = deque([(1, 0)])
        while queue:
            orc, count = queue.popleft()
            dead_ancestors[orc] = count
            child_count = count + (1 if is_dead[orc] else 0)
            for neighbour in children[orc]:
                if not visited[neighbour]:
                    visited[neighbour] = True
                    queue.append((neighbour, child_count))
        expected = 0.0
        for orc in range(1, orc_count + 1):
            count = dead_ancestors[orc]
            expected += count / (count + 1)
        lines.append(("%.6f" % expected).rstrip("0").rstrip("."))
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n0\n\n") == "0\n"
assert brute_force(2, [(1, 2)], [1]) == 0.5
assert brute_force(2, [(1, 2)], [2]) == 0.0
assert brute_force(3, [(1, 2), (1, 3)], [1]) == 1.0
assert brute_force(3, [(1, 2), (2, 3)], [2]) == 0.5


def tree_edges(orc_count, rng, shape):
    if shape == "chain":
        return [(label, label + 1) for label in range(1, orc_count)]
    if shape == "star":
        return [(1, label) for label in range(2, orc_count + 1)]
    return [(rng.randint(1, label - 1), label) for label in range(2, orc_count + 1)]


def write(name, cases):
    parts = [str(len(cases))]
    for orc_count, edges, dead in cases:
        parts.append(str(orc_count))
        for first, second in edges:
            parts.append(f"{first} {second}")
        parts.append(str(len(dead)))
        if dead:
            parts.append(" ".join(str(orc) for orc in dead))
        else:
            parts.append("")
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        (1, [], []),
        (2, [(1, 2)], [1]),
        (2, [(1, 2)], [2]),
        (3, [(1, 2), (2, 3)], [1, 3]),
    ])
    write("3_wide", [
        (12, tree_edges(12, rng, "chain"), list(range(1, 13))),
        (12, tree_edges(12, rng, "star"), list(range(2, 13))),
    ])
    write("4_random", [
        (25, tree_edges(25, rng, "random"), sorted(rng.sample(range(1, 26), 11))),
        (18, tree_edges(18, rng, "chain"), sorted(rng.sample(range(1, 19), 7))),
    ])
    write("5_io", [
        (60000, tree_edges(60000, rng, "random"), sorted(rng.sample(range(1, 60001), 20000))),
        (40000, tree_edges(40000, rng, "chain"), sorted(rng.sample(range(1, 40001), 10000))),
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
