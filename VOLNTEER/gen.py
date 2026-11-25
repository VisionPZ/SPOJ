#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def group_score(group):
    total = sum(abs(value) for value in group)
    naughty = sum(1 for value in group if value < 0)
    return -total if naughty % 2 else total


def brute(values, count):
    return max(group_score(group) for group in itertools.combinations(values, count))


def ranked(values, count):
    positives = sorted((abs(value) for value in values if value >= 0), reverse=True)
    negatives = sorted((-value for value in values if value < 0), reverse=True)
    best = None
    for negatives_used in range(min(count, len(negatives)) + 1):
        positives_used = count - negatives_used
        if positives_used > len(positives):
            continue
        if negatives_used % 2:
            total = sum(positives[len(positives) - positives_used:]) + sum(negatives[len(negatives) - negatives_used:])
        else:
            total = sum(positives[:positives_used]) + sum(negatives[:negatives_used])
        score = -total if negatives_used % 2 else total
        if best is None or score > best:
            best = score
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    group_size = tokens[1]
    values = tokens[2:2 + count]
    if count <= 16:
        return str(brute(values, group_size)) + "\n"
    return str(ranked(values, group_size)) + "\n"


SAMPLE = """10 1
1 2 3 4 5 6 7 8 -9 9
"""
SAMPLE_OUT = """9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("10 3\n1 2 3 4 5 6 7 -8 -9 9\n") == "26\n"
assert oracle("3 3\n12 78 2\n") == "92\n"
assert oracle("2 2\n-5 -3\n") == "8\n"
assert oracle("4 2\n-1 2 3 4\n") == "7\n"

rng = random.Random(7)
for _ in range(300):
    sample = [rng.randint(-9, 9) for _ in range(8)]
    for size in range(1, 9):
        assert brute(sample, size) == ranked(sample, size)


def write(name, values, group_size):
    text = f"{len(values)} {group_size}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [-1, -2, -3, -4], 3)
    write("3_wide", [1000000000] * 50 + [-1000000000] * 50, 100)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(-1000000000, 1000000000) for _ in range(200)], 120)
    write("5_io", [rng.randint(-1000000000, 1000000000) for _ in range(100000)], 50000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 4, 5, 6, 7, 8, -9, 9], 1)
build()
