#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    tree_count = tokens[0]
    required_wood = tokens[1]
    heights = tokens[2:2 + tree_count]
    ordered = sorted(heights)
    prefix = [0]
    for value in ordered:
        prefix.append(prefix[-1] + value)
    total_trees = len(ordered)
    best_height = 0
    for height in range(max(ordered) + 1):
        first_cut = bisect.bisect_right(ordered, height)
        cut_count = total_trees - first_cut
        wood = prefix[total_trees] - prefix[first_cut] - height * cut_count
        if wood >= required_wood:
            best_height = height
    return str(best_height) + "\n"


SAMPLE = """4 7
20 15 10 17
"""
SAMPLE_OUT = """15
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5 20\n4 42 40 26 46\n") == "36\n"
assert oracle("1 1\n5\n") == "4\n"
assert oracle("3 6\n1 2 3\n") == "0\n"
assert oracle("3 1\n9 9 9\n") == "8\n"


def write(name, tree_count, required_wood, heights):
    text = f"{tree_count} {required_wood}\n" + " ".join(str(value) for value in heights) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, [5])
    write("3_wide", 1000, 100000, [10000] * 1000)
    rng = random.Random(20261126)
    heights = [rng.randint(1, 5000) for _ in range(2000)]
    write("4_random", 2000, rng.randint(1, sum(heights)), heights)
    heights = [rng.randint(1, 1000) for _ in range(200000)]
    write("5_io", 200000, rng.randint(1, 1000000), heights)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 4, 7, [20, 15, 10, 17])
build()
