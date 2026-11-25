#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    row_count = tokens[0]
    values = tokens[1:]
    rows = [values[3 * index:3 * index + 3] for index in range(row_count)]
    step_count = max(0, row_count - 1)
    best_at = []
    for position in range(step_count):
        left = sum(rows[position][0:2]) + sum(rows[position + 1][0:2])
        right = sum(rows[position][1:3]) + sum(rows[position + 1][1:3])
        best_at.append(max(left, right))
    best = 0
    for take_count in range(step_count + 1):
        for positions in itertools.combinations(range(step_count), take_count):
            if any(positions[index + 1] - positions[index] < 2
                   for index in range(len(positions) - 1)):
                continue
            total = sum(best_at[position] for position in positions)
            if total > best:
                best = total
    return str(best) + "\n"


SAMPLE = """7
7 1 11
6 3 9
-4 -2 8
-8 -10 17
5 4 -3
-1 2 0
3 9 -3
"""
SAMPLE_OUT = """50
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5 5 5\n") == "0\n"
assert oracle("2\n1 2 3\n4 5 6\n") == "16\n"
assert oracle("3\n-9 -9 -9\n-9 -9 -9\n-9 -9 -9\n") == "0\n"
assert oracle("4\n-1 -1 -1\n9 9 9\n-1 -1 -1\n9 9 9\n") == "32\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1\n0 0 0\n")
    write("3_wide", "5\n" + "\n".join(
        "1000000000 1000000000 1000000000" for _ in range(5)) + "\n")
    rng = random.Random(20261126)
    rows = []
    for _ in range(12):
        rows.append(" ".join(str(rng.randint(-1000000000, 1000000000))
                             for _ in range(3)))
    write("4_random", "12\n" + "\n".join(rows) + "\n")
    write("5_io", "14\n" + "\n".join(
        "1000000000 1000000000 -1000000000" for _ in range(14)) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
