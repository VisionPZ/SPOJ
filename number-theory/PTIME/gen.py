#!/usr/bin/env python3
import math
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def factor_exponents(limit):
    remaining = math.factorial(limit)
    exponents = []
    for divisor in range(2, limit + 1):
        exponent = 0
        while remaining % divisor == 0:
            remaining //= divisor
            exponent += 1
        if exponent:
            exponents.append((divisor, exponent))
    assert remaining == 1
    return exponents


def oracle(text):
    lines = []
    for token in text.split():
        limit = int(token)
        parts = [f"{prime}^{exponent}" for prime, exponent in factor_exponents(limit)]
        lines.append(" * ".join(parts))
    return "\n".join(lines) + "\n"


SAMPLE = """10
"""
SAMPLE_OUT = """2^8 * 3^4 * 5^2 * 7^1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n") == "2^1\n"
assert oracle("3\n") == "2^1 * 3^1\n"
assert oracle("4\n") == "2^3 * 3^1\n"
assert oracle("7\n") == "2^4 * 3^2 * 5^1 * 7^1\n"


def write(name, limits):
    text = "".join(f"{limit}\n" for limit in limits)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [2, 3, 4, 5, 6, 7, 9999, 10000])
    write("3_wide", [10000] * 8)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(2, 10000) for _ in range(120)])
    write("5_io", [10000] * 120)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [10])
build()
