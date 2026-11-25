#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def hexagon_count(level):
    def inside(a, b):
        return abs(a) <= level and abs(b) <= level and abs(a + b) <= level

    points = set()
    for a in range(-level - 1, level + 2):
        for b in range(-level - 1, level + 2):
            if inside(a, b):
                points.add((a, b))
    limit = 2 * level + 1
    total = 0
    for side in range(1, limit + 1):
        for a in range(-limit - 1, limit + 2):
            for b in range(-limit - 1, limit + 2):
                if (a, b) in points and (a + side, b) in points and (a, b + side) in points:
                    total += 1
                if (a + side, b) in points and (a, b + side) in points and (a + side, b + side) in points:
                    total += 1
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = [str(hexagon_count(tokens[index + 1])) for index in range(case_count)]
    return "\n".join(answers) + "\n"


SAMPLE = "1\n1\n"
SAMPLE_OUT = "6\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "38\n"
assert oracle("1\n3\n") == "116\n"
assert oracle("1\n5\n") == "496\n"
assert oracle("2\n1\n4\n") == "6\n262\n"


def write(name, levels):
    text = str(len(levels)) + "\n" + "".join(str(level) + "\n" for level in levels)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [10, 11, 12])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 12) for _ in range(60)])
    write("5_io", [rng.choice([3, 4, 5, 6]) for _ in range(3000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1])
build()
