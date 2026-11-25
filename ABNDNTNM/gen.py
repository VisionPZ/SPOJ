#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def proper_divisor_sum(number):
    if number < 2:
        return 0
    total = 1
    divisor = 2
    while divisor * divisor <= number:
        if number % divisor == 0:
            total += divisor
            partner = number // divisor
            if partner != divisor:
                total += partner
        divisor += 1
    return total


def oracle(text):
    lower, upper = (int(value) for value in text.split())
    count = 0
    for number in range(max(1, lower), upper + 1):
        if proper_divisor_sum(number) > number:
            count += 1
    return str(count) + "\n"


SAMPLE = """204 1007
"""
SAMPLE_OUT = """201
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 11\n") == "0\n"
assert oracle("11 12\n") == "1\n"
assert oracle("1 30\n") == "5\n"
assert oracle("1 100\n") == "22\n"
assert oracle("1 1000\n") == "246\n"
assert proper_divisor_sum(12) == 16


def write(name, lower, upper):
    text = f"{lower} {upper}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 12)
    write("3_wide", 1, 5000)
    rng = random.Random(20261126)
    lower = rng.randint(1, 20000)
    write("4_random", lower, lower + rng.randint(1, 3000))
    write("5_io", 1, 50000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 204, 1007)
build()
