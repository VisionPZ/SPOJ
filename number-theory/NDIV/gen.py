#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(value) for value in text.split()]
    low_bound, high_bound, target = values[0], values[1], values[2]
    divisor_counts = [0] * (high_bound - low_bound + 1)
    divisor = 1
    while divisor * divisor <= high_bound:
        first_multiple = ((low_bound + divisor - 1) // divisor) * divisor
        for number in range(first_multiple, high_bound + 1, divisor):
            if divisor * divisor > number:
                continue
            index = number - low_bound
            divisor_counts[index] += 1
            if divisor * divisor != number:
                divisor_counts[index] += 1
        divisor += 1
    return str(sum(1 for count in divisor_counts if count == target)) + "\n"


SAMPLE = "1 7 2\n"
SAMPLE_OUT = "4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 1\n") == "1\n"
assert oracle("1 10 4\n") == "3\n"
assert oracle("100 100 9\n") == "1\n"
assert oracle("2 2 2\n") == "1\n"


def write(name, low_bound, high_bound, target):
    text = f"{low_bound} {high_bound} {target}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, 1)
    write("3_wide", 999990000, 1000000000, 100)
    rng = random.Random(20261126)
    low_bound = rng.randint(1, 1000000000 - 10000)
    write("4_random", low_bound, low_bound + rng.randint(0, 10000), rng.randint(1, 100))
    low_bound = 1000000000 - 10000
    write("5_io", low_bound, 1000000000, 2)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 1, 7, 2)
build()
