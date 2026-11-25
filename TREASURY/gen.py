#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(parents):
    clerk_count = len(parents)
    edges = [(parent, child + 1) for child, parent in enumerate(parents) if parent != 0]
    best_size = -1
    best_count = 0
    for mask in range(1 << len(edges)):
        used = set()
        size = 0
        valid = True
        for edge_index, (supervisor, subordinate) in enumerate(edges):
            if not (mask >> edge_index) & 1:
                continue
            if supervisor in used or subordinate in used:
                valid = False
                break
            used.add(supervisor)
            used.add(subordinate)
            size += 1
        if valid and size > best_size:
            best_size = size
            best_count = 1
        elif valid and size == best_size:
            best_count += 1
    if clerk_count == 1:
        return "0\n1\n"
    return f"{best_size}\n{best_count}\n"


def oracle_text(cases):
    return "".join(oracle(parents) for parents in cases)


def to_text(parents):
    clerk_count = len(parents)
    children = [[] for _ in range(clerk_count + 1)]
    for child, parent in enumerate(parents):
        if parent != 0:
            children[parent].append(child + 1)
    lines = [str(clerk_count)]
    for clerk_id in range(1, clerk_count + 1):
        part = [str(clerk_id), str(len(children[clerk_id]))]
        part.extend(str(value) for value in children[clerk_id])
        lines.append(" ".join(part))
    return "\n".join(lines) + "\n"


SAMPLE_PARENTS = [0, 1, 2, 1, 7, 4, 1]
SAMPLE = """7
1 3 2 4 7
2 1 3
4 1 6
3 0
7 1 5
5 0
6 0
"""
SAMPLE_OUT = """3
4
"""
assert oracle(SAMPLE_PARENTS) == SAMPLE_OUT
assert oracle([0, 1, 2, 3]) == "2\n1\n"
assert oracle([0, 1, 1, 1, 1]) == "1\n4\n"
assert oracle([0]) == "0\n1\n"
assert oracle([0, 1, 1, 1, 1, 1, 2, 2, 2]) == "2\n12\n"


def write(name, cases):
    (ROOT / "in" / f"{name}.txt").write_text("".join(to_text(parents) for parents in cases))
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


def build():
    rng = random.Random(20261126)
    write("2_edges", [[0], [0, 1], [0, 1, 2, 3], [0, 1, 1, 1, 1],
                      [0, 1, 2, 1, 4, 4, 4]])
    write("3_wide", [[0] + [rng.randrange(1, child) for child in range(2, 13)]
                     for _ in range(20)])
    write("4_random", [[0] + [rng.randrange(1, child) for child in range(2, rng.randint(4, 14))]
                       for _ in range(20)])
    write("5_io", [[0] + [rng.randrange(1, child) for child in range(2, rng.randint(4, 14))]
                   for _ in range(150)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
