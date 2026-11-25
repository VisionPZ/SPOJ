#!/usr/bin/env python3
import random
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    vertex_count = tokens[0]
    commodity_count = tokens[1]
    root = vertex_count - 1
    pairs = []
    cursor = 2
    for _ in range(commodity_count):
        pairs.append((tokens[cursor], tokens[cursor + 1]))
        cursor += 2
    if commodity_count == 0:
        return "0\n"
    best = commodity_count + 1
    for mask in range(1 << max(0, vertex_count - 1)):
        cut = [bool(mask & (1 << leaf)) for leaf in range(vertex_count - 1)]
        worst = 0
        valid = True
        for first, second in pairs:
            count = 0
            if first != root:
                count += int(cut[first])
            if second != root:
                count += int(cut[second])
            if count == 0:
                valid = False
                break
            worst = max(worst, count)
        if valid and worst < best:
            best = worst
    return str(best) + "\n"


SAMPLE = """10 2
0 5
4 8
"""
SAMPLE_OUT = """1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 1\n0 2\n") == "1\n"
assert oracle("4 3\n0 1\n1 2\n0 2\n") == "2\n"
assert oracle("4 3\n0 3\n1 3\n2 3\n") == "1\n"
assert oracle("5 3\n0 1\n1 2\n0 2\n") == "2\n"


def write(name, vertex_count, pairs):
    text = f"{vertex_count} {len(pairs)}\n" + "".join(
        f"{first} {second}\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 4, [(0, 1), (1, 2), (0, 2)])
    write("3_wide", 8, [(0, 1), (2, 3), (4, 5), (6, 7), (0, 7)])
    rng = random.Random(20261126)
    vertices = list(range(8))
    pairs = []
    for pair in combinations(vertices, 2):
        if rng.random() < 0.45:
            pairs.append(pair)
    write("4_random", 8, pairs)
    leaf_count = 100000
    forced = [(leaf, leaf_count) for leaf in range(leaf_count)]
    text = f"{leaf_count + 1} {len(forced)}\n" + "".join(
        f"{first} {second}\n" for first, second in forced)
    (ROOT / "in" / "5_io.txt").write_text(text)
    (ROOT / "out" / "5_io.out").write_text("1\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 10, [(0, 5), (4, 8)])
build()
