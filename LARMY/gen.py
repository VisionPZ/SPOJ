#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MASTER_RNG = random.Random(20261126)


def inversion_count(heights, left, right):
    total = 0
    for first in range(left, right):
        for second in range(first + 1, right + 1):
            if heights[first] > heights[second]:
                total += 1
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    warrior_count = tokens[0]
    wanted_rows = tokens[1]
    heights = tokens[2:2 + warrior_count]
    if wanted_rows >= warrior_count:
        return "0\n"
    previous = [inversion_count(heights, 0, end) for end in range(warrior_count)]
    for _ in range(2, wanted_rows + 1):
        current = [10 ** 9] * warrior_count
        for end in range(warrior_count):
            best = 10 ** 9
            for split in range(end):
                candidate = previous[split] + inversion_count(heights, split + 1, end)
                if candidate < best:
                    best = candidate
            current[end] = best
        previous = current
    return str(previous[warrior_count - 1]) + "\n"


SAMPLE_A = """6 3
20 50 30 60 40 100
"""
SAMPLE_B = """8 3
20 50 30 60 40 100 5 1
"""
assert oracle(SAMPLE_A) == "0\n"
assert oracle(SAMPLE_B) == "2\n"
assert oracle("5 1\n5 4 3 2 1\n") == "10\n"
assert oracle("5 5\n5 4 3 2 1\n") == "0\n"
assert oracle("4 2\n4 3 2 1\n") == "2\n"


def write(name, warrior_count, wanted_rows, heights):
    text = f"{warrior_count} {wanted_rows}\n" + " ".join(str(value) for value in heights) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", 5, 5, [5, 4, 3, 2, 1])
    write("3_wide", 12, 3,
          [100000, 1, 100000, 1, 100000, 1, 100000, 1, 100000, 1, 100000, 1])
    count = 14
    write("4_random", count, rng.randint(1, count),
          [rng.randint(1, 100000) for _ in range(count)])
    count = 40
    write("5_io", count, 20, [rng.randint(1, 100000) for _ in range(count)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_A)
(ROOT / "out" / "1_sample.out").write_text("0\n")
big_lines = ["5000 2500"]
big_lines.append(" ".join(str(MASTER_RNG.randint(1, 100000)) for _ in range(5000)))
Path("/tmp/LARMY_big.txt").write_text("\n".join(big_lines) + "\n")
build()
