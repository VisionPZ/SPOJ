#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE = "100\n"
SAMPLE_OUT = "2 x 2 x 5 x 5\n"


def prime_sieve(limit):
    is_composite = bytearray(limit + 1)
    primes = []
    for candidate in range(2, limit + 1):
        if not is_composite[candidate]:
            primes.append(candidate)
            for multiple in range(candidate * candidate, limit + 1, candidate):
                is_composite[multiple] = 1
    return primes


def factor_by_primes(value, primes):
    factors = []
    for prime in primes:
        if prime * prime > value:
            break
        while value % prime == 0:
            factors.append(prime)
            value //= prime
    if value > 1:
        factors.append(value)
    return factors


def oracle(text):
    values = [int(token) for token in text.split()]
    largest = max(values, default=1)
    primes = prime_sieve(math.isqrt(largest))
    lines = []
    for value in values:
        lines.append(" x ".join(str(factor) for factor in
                                factor_by_primes(value, primes)))
    return "\n".join(lines) + "\n" if lines else ""


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("49\n") == "7 x 7\n"
assert oracle("12\n") == "2 x 2 x 3\n"
assert oracle("2\n") == "2\n"
assert oracle("360\n") == "2 x 2 x 2 x 3 x 3 x 5\n"


def write(name, values):
    input_text = "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [4, 6, 9, 49, 2, 97, 1000003, 999983, 360, 1024])
    write("3_wide", [10**12, 999999937 * 3, 2**40, 999999996, 10**9 + 7])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(2, 10**6) for _ in range(300)])
    write("5_io", [rng.randint(2, 10**6) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [100])
build()
