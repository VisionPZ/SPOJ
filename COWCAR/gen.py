#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def feasible(speeds, lane_count, slowdown, limit):
    for position, speed in enumerate(speeds):
        if speed - slowdown * (position // lane_count) < limit:
            return False
    return True


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cow_count, lane_count, slowdown, limit = tokens[:4]
    speeds = sorted(tokens[4:4 + cow_count])
    low = 0
    high = cow_count
    while low < high:
        middle = (low + high + 1) // 2
        if feasible(speeds[cow_count - middle:], lane_count, slowdown, limit):
            low = middle
        else:
            high = middle - 1
    return str(low) + "\n"


def brute(text):
    tokens = [int(value) for value in text.split()]
    cow_count, lane_count, slowdown, limit = tokens[:4]
    speeds = tokens[4:4 + cow_count]
    best = 0
    for size in range(cow_count + 1):
        for chosen in itertools.combinations(speeds, size):
            if feasible(sorted(chosen), lane_count, slowdown, limit):
                best = max(best, size)
    return str(best) + "\n"


SAMPLE = """3 1 1 5
5
7
5
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("3 3 0 5\n4 5 6\n") == "2\n"
assert brute("3 3 0 5\n4 5 6\n") == "2\n"
assert oracle("4 2 10 5\n1 2 3 4\n") == "0\n"
assert oracle("4 1 0 5\n5 5 5 5\n") == "4\n"


def write(name, cow_count, lane_count, slowdown, limit, speeds):
    lines = [f"{cow_count} {lane_count} {slowdown} {limit}"]
    lines.extend(str(value) for value in speeds)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 4, 1, 0, 5, [5, 5, 5, 5])
    write("3_wide", 5, 2, 5000, 1000000, [1000000] * 5)
    rng = random.Random(20261126)
    write("4_random", 500, rng.randint(1, 500), rng.randint(0, 5000),
          rng.randint(1, 1000000), [rng.randint(1, 1000000) for _ in range(500)])
    write("5_io", 50000, 1000, 1, 500000,
          [rng.randint(1, 1000000) for _ in range(50000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
