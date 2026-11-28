#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    tree_count = tokens[0]
    reach_meters = tokens[1]
    fruits = tokens[2:2 + tree_count]
    reach_trees = reach_meters // 3
    prefix = [0]
    for value in fruits:
        prefix.append(prefix[-1] + value)
    best = 0
    for center in range(tree_count):
        left = max(0, center - reach_trees)
        right = min(tree_count - 1, center + reach_trees)
        total = prefix[right + 1] - prefix[left]
        if total > best:
            best = total
    return str(best) + "\n"


SAMPLE = """5 3
1 2 2 2 1
"""
SAMPLE_OUT = """6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 3\n7\n") == "7\n"
assert oracle("3 0\n1 2 3\n") == "3\n"
assert oracle("3 100\n1 2 3\n") == "6\n"
assert 31 // 3 == 10


def write(name, reach, fruits):
    text = f"{len(fruits)} {reach}\n" + " ".join(str(value) for value in fruits) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 0, [1, 2, 3, 4, 5])
    write("3_wide", 1000000000, [1000000000] * 100)
    rng = random.Random(20261126)
    write("4_random", rng.randint(0, 1000000000),
          [rng.randint(0, 1000000000) for _ in range(100)])
    write("5_io", 300, [1000000000 if index % 3 else 0 for index in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, [1, 2, 2, 2, 1])
build()
