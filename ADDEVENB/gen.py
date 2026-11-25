#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    distance = tokens[1]
    values = tokens[2:2 + count]
    total = 0
    for left_index in range(count):
        right_limit = min(count, left_index + distance + 1)
        for right_index in range(left_index + 1, right_limit):
            if (values[left_index] + values[right_index]) % 2 == 0:
                total += 1
    return str(total) + "\n"


SAMPLE = """3 1
1 1 1
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("6 4\n2 12 3 14 29 4\n") == "6\n"
assert oracle("2 1\n1 2\n") == "0\n"
assert oracle("4 2\n2 4 6 8\n") == "5\n"
assert oracle("5 1\n1 3 5 7 9\n") == "4\n"


def write(name, count, distance, values):
    text = f"{count} {distance}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 4, 1, [1, 2, 3, 4])
    write("3_wide", 2000, 3, [2] * 2000)
    rng = random.Random(20261126)
    write("4_random", 1500, 7, [rng.randint(1, 1000000000) for _ in range(1500)])
    write("5_io", 2000, 50, [rng.choice([2, 3, 1000000000000]) for _ in range(2000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, 1, [1, 1, 1])
build()
