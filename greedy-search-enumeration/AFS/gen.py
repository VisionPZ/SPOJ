#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def term(value):
    total = 0
    left = 1
    while left < value:
        quotient = value // left
        right = min(value - 1, value // quotient)
        divisor_sum = (left + right) * (right - left + 1) // 2
        total += divisor_sum * (quotient - 1)
        left = right + 1
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    return "".join(str(term(tokens[index + 1])) + "\n" for index in range(count))


SAMPLE = """3
3
4
5
"""
SAMPLE_OUT = """2
5
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "1\n"
assert oracle("1\n3\n") == "2\n"
assert oracle("4\n2\n3\n4\n5\n") == "1\n2\n5\n6\n"
assert term(100) == sum(sum(d for d in range(1, k) if k % d == 0) for k in range(2, 101))


def write(name, values):
    text = str(len(values)) + "\n" + "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [2, 2, 3, 4])
    write("3_wide", [999999, 1000000, 999998, 500000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(2, 1000000) for _ in range(100)])
    write("5_io", [rng.randint(2, 1000000) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 4, 5])
build()
