#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIMIT = 100000


def build_depth(limit):
    cubes = [root ** 3 for root in range(1, 47) if root ** 3 <= limit]
    mask = (1 << (limit + 1)) - 1
    seen = 1
    frontier = 1
    depth = [0] * (limit + 1)
    level = 0
    while frontier:
        level += 1
        reached = 0
        for cube in cubes:
            reached |= frontier << cube
        reached &= mask & ~seen
        if reached == 0:
            break
        current = reached
        while current:
            lowest = current & -current
            depth[lowest.bit_length() - 1] = level
            current ^= lowest
        seen |= reached
        frontier = reached
    return depth


DEPTH = build_depth(LIMIT)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    lines = []
    for index, value in enumerate(tokens, 1):
        lines.append(f"Case #{index}: {DEPTH[value]}")
    return "\n".join(lines) + "\n"


SAMPLE = """1
2
5
8
35
"""
SAMPLE_OUT = """Case #1: 1
Case #2: 2
Case #3: 5
Case #4: 1
Case #5: 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "Case #1: 1\n"
assert oracle("100000\n") == "Case #1: 4\n"
assert oracle("23\n239\n") == "Case #1: 9\nCase #2: 9\n"
assert DEPTH[97336] == 1 and DEPTH[97337] == 2


def write(name, values):
    text = "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 8, 27, 23, 239, 97336, 97337])
    write("3_wide", [100000, 99999, 99998] + [100000 - cube for cube in (1, 8, 27, 64)])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, LIMIT) for _ in range(1000)])
    write("5_io", [rng.randint(1, LIMIT) for _ in range(99999)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 5, 8, 35])
build()
