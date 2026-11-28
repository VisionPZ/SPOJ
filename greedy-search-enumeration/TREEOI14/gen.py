#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    heights = tokens[1:1 + count]
    answers = []
    base_disorder = sum(abs(heights[index] - heights[index + 1])
                        for index in range(count - 1))
    for fixed in range(count):
        best = base_disorder
        for other in range(count):
            if other == fixed:
                continue
            changed = list(heights)
            changed[fixed], changed[other] = changed[other], changed[fixed]
            disorder = sum(abs(changed[index] - changed[index + 1])
                           for index in range(count - 1))
            if best is None or disorder < best:
                best = disorder
        if best is None:
            best = sum(abs(heights[index] - heights[index + 1])
                       for index in range(count - 1))
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """5
7 4 5 2 5
"""
SAMPLE_OUT = """7
7
8
7
7
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n3 9\n") == "6\n6\n"
assert oracle("3\n1 2 3\n") == "2\n2\n2\n"
assert oracle("4\n5 5 5 5\n") == "0\n0\n0\n0\n"


def write(name, heights):
    text = str(len(heights)) + "\n" + " ".join(str(value) for value in heights) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [1, 100000000, 1, 100000000, 1])
    write("3_wide", [rng.randrange(1, 100000001) for _ in range(40)])
    write("4_random", [rng.randint(1, 30) for _ in range(35)])
    write("5_io", [rng.randint(1, 100000000) for _ in range(60)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [7, 4, 5, 2, 5])
build()
