#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    target = int(text.split()[0])
    total = 0
    step = 1
    while step * step <= target:
        if target % step == 0:
            partner = target // step
            for divisor in {step, partner}:
                upper_sum = divisor + 1
                for first in range(1, upper_sum // 2 + 1):
                    if math.gcd(first, upper_sum) == 1:
                        total += 1
        step += 1
    return str(total) + "\n"


def brute(text):
    target = int(text.split()[0])
    total = 0
    for first in range(1, target + 1):
        for second in range(first, target + 1):
            if first + second - math.gcd(first, second) == target:
                total += 1
    return str(total) + "\n"


SAMPLE = """4
"""
SAMPLE_OUT = """4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "1\n"
assert brute("1\n") == "1\n"
assert oracle("2\n") == "2\n"
assert brute("2\n") == "2\n"
assert oracle("6\n") == "6\n"
assert brute("6\n") == "6\n"


def write(name, target):
    text = str(target) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 997920)
    rng = random.Random(20261126)
    write("4_random", rng.randint(100, 999999))
    write("5_io", 999999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 4)
build()
