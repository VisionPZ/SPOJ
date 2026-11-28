#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    values = tokens[1:1 + count]
    total = 0
    for left_index in range(count):
        for right_index in range(left_index + 1, count):
            if (values[left_index] + values[right_index]) % 2 == 0:
                total += 1
    return str(total) + "\n"


SAMPLE = """3
1 1 1
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("6\n2 12 3 14 29 4\n") == "7\n"
assert oracle("2\n1 2\n") == "0\n"
assert oracle("4\n7 9 11 13\n") == "6\n"
assert oracle("5\n2 4 6 8 10\n") == "10\n"


def write(name, values):
    text = str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 4, 7])
    write("3_wide", [2] * 2000)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000000) for _ in range(1500)])
    write("5_io", [rng.choice([2, 3, 1000000000000]) for _ in range(2500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 1, 1])
build()
