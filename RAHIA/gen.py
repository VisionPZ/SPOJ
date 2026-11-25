#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    values = tokens[1:1 + count]
    running_minimum = None
    for index in range(count - 1, -1, -1):
        difference = values[index] - index
        if running_minimum is None or difference < running_minimum:
            running_minimum = difference
    return "YES\n" if running_minimum >= 0 else "NO\n"


SAMPLE = "7\n5 2 3 9 88 9 10\n"
SAMPLE_OUT = "YES\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "YES\n"
assert oracle("3\n1 1 1\n") == "NO\n"
assert oracle("3\n3 1 2\n") == "YES\n"
assert oracle("4\n4 3 2 1\n") == "NO\n"
assert oracle("2\n1000000000 1\n") == "YES\n"


def write(name, values):
    text = str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 1, 1])
    write("3_wide", list(range(1, 100001)))
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 10**9) for _ in range(10000)])
    write("5_io", [rng.randint(1, 10**9) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [5, 2, 3, 9, 88, 9, 10])
build()
