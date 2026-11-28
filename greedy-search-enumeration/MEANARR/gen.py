#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    element_count = tokens[0]
    required_mean = tokens[1]
    values = tokens[2:2 + element_count]
    qualifying = 0
    for start in range(element_count):
        running_sum = 0
        for end in range(start, element_count):
            running_sum += values[end]
            if running_sum >= required_mean * (end - start + 1):
                qualifying += 1
    return str(qualifying) + "\n"


SAMPLE = """5 4
5 2 4 5 1
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n7\n") == "1\n"
assert oracle("1 8\n7\n") == "0\n"
assert oracle("4 1\n3 4 5 6\n") == "10\n"
assert oracle("3 3\n3 3 3\n") == "6\n"


def write(name, required_mean, values):
    text = f"{len(values)} {required_mean}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 100, [1, 1, 1, 1, 1])
    write("3_wide", 2147483647, [2147483647] * 900 + [1] * 900)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 2147483647),
          [rng.randint(1, 2147483647) for _ in range(1200)])
    write("5_io", 1000, [1000 if index % 2 == 0 else 1 for index in range(2500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 4, [5, 2, 4, 5, 1])
build()
