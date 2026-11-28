#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(value) for value in text.split()][:6]
    exponent_by_prime = {}
    for value in values:
        divisor = 2
        remaining = value
        while divisor * divisor <= remaining:
            while remaining % divisor == 0:
                exponent_by_prime[divisor] = exponent_by_prime.get(divisor, 0) + 1
                remaining //= divisor
            divisor += 1
        if remaining > 1:
            exponent_by_prime[remaining] = exponent_by_prime.get(remaining, 0) + 1
    total = 1
    for prime, exponent in exponent_by_prime.items():
        total *= prime ** exponent
    return str(total) + "\n"


SAMPLE = """1 1 1 2 1 1
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 3 1 2 4 1\n") == "48\n"
assert oracle("5 10 2 8 7 4\n") == "22400\n"
assert oracle("1 1 1 1 1 1\n") == "1\n"
assert oracle("50 50 50 50 50 50\n") == str(50 ** 6) + "\n"


def write(name, values):
    text = " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 1, 1, 1, 1, 1])
    write("3_wide", [50, 50, 50, 50, 50, 50])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 50) for _ in range(6)])
    write("5_io", [50, 50, 50, 50, 50, 50])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 1, 1, 2, 1, 1])
build()
