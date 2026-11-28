#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def mobius(value):
    factor_count = 0
    remaining = value
    divisor = 2
    while divisor * divisor <= remaining:
        if remaining % divisor == 0:
            factor_count += 1
            remaining //= divisor
            if remaining % divisor == 0:
                return 0
        divisor += 1
    if remaining > 1:
        factor_count += 1
    return -1 if factor_count % 2 else 1


def oracle(text):
    class_size = int(text.split()[0])
    total = 0
    divisor = 1
    while divisor * divisor <= class_size:
        if class_size % divisor == 0:
            paired = class_size // divisor
            total += mobius(divisor) * (class_size // divisor)
            if paired != divisor:
                total += mobius(paired) * (class_size // paired)
        divisor += 1
    return str(total) + "\n"


def brute_count(class_size):
    return sum(1 for roll in range(1, class_size + 1)
               if math.gcd(roll, class_size) == 1)


SAMPLE = "1\n"
SAMPLE_OUT = "1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n") == "1\n"
assert oracle("6\n") == "2\n"
assert oracle("1000000000\n") == "400000000\n"
for class_size in range(1, 300):
    assert oracle(str(class_size) + "\n") == str(brute_count(class_size)) + "\n"


def write(name, class_size):
    text = str(class_size) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2)
    write("3_wide", 1000000000)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 1000000000))
    write("5_io", 999999937)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 1)
build()
