#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    tree_count = tokens[0]
    heights = tokens[1:1 + tree_count]
    candidates = set(heights)
    candidates.add(0)
    best_cost = None
    for target in candidates:
        total_cost = 0
        for height in heights:
            if height < target:
                total_cost += height
            else:
                total_cost += height - target
        if best_cost is None or total_cost < best_cost:
            best_cost = total_cost
    return str(best_cost) + "\n"


SAMPLE = """5
1 2 3 4 5
"""
SAMPLE_OUT = """6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n1 4 2\n") == "3\n"
assert oracle("4\n1 6 1 1\n") == "3\n"
assert oracle("6\n7 11 13 1 3 5\n") == "18\n"
assert oracle("7\n1 11 4 13 5 10 7\n") == "21\n"
assert oracle("1\n0\n") == "0\n"
assert oracle("2\n1000000000 1000000000\n") == "0\n"


def write(name, heights):
    text = str(len(heights)) + "\n" + " ".join(str(value) for value in heights) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    write("2_edges", [0] * 5 + [1000000000] * 5)
    write("3_wide", [1000000000 if index % 2 else 0 for index in range(500)])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 1000) for _ in range(300)])
    palette = [rng.randint(0, 1000000000) for _ in range(20)]
    write("5_io", [palette[rng.randrange(20)] for _ in range(200000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 4, 5])
build()
