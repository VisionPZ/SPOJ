#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(token) for token in text.split()]
    queries = [value for value in values if value >= 0]
    largest = max(queries, default=0)
    sequence = [0] * (largest + 1)
    used = {0}
    for index in range(1, largest + 1):
        previous = sequence[index - 1]
        below = previous - index
        if below > 0 and below not in used:
            sequence[index] = below
        else:
            sequence[index] = previous + index
        used.add(sequence[index])
    return "".join(str(sequence[value]) + "\n" for value in queries)


SAMPLE = """7
10000
-1
"""
SAMPLE_OUT = """20
18658
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0\n1\n2\n3\n4\n-1\n") == "0\n1\n3\n6\n2\n"
assert oracle("5\n6\n7\n-1\n") == "7\n13\n20\n"
assert oracle("14\n-1\n") == "9\n"


def write(name, indices):
    text = "".join(str(index) + "\n" for index in indices) + "-1\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 5, 500000])
    write("3_wide", [500000, 499999, 250000, 123456])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 500000) for _ in range(200)])
    write("5_io", [rng.randint(0, 500000) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
