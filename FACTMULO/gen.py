#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def exponent_in_factorial(value, prime):
    exponent = 0
    while value:
        value //= prime
        exponent += value
    return exponent


def brute(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    results = []
    for case in range(count):
        prime = tokens[1 + 2 * case]
        limit = tokens[2 + 2 * case]
        total = 0
        for number in range(1, limit + 1):
            total += exponent_in_factorial(number, prime)
        results.append(str(total))
    return "\n".join(results) + "\n"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    results = []
    for case in range(count):
        prime = tokens[1 + 2 * case]
        limit = tokens[2 + 2 * case]
        total = 0
        power = prime
        while power <= limit:
            quotient = limit // power
            total += quotient * (limit + 1) - power * quotient * (quotient + 1) // 2
            power *= prime
        results.append(str(total))
    return "\n".join(results) + "\n"


SAMPLE = """2
2 3
3 4
"""
SAMPLE_OUT = """2
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 4\n") == "5\n"
assert oracle("1\n5 1\n") == "0\n"
assert oracle("1\n2 1000000000000000000\n") == "499999999999999970738777216570753000\n"
for trial_prime in (2, 3, 5, 7, 11):
    for trial_limit in (1, 2, 3, 7, 20, 50):
        assert oracle(f"1\n{trial_prime} {trial_limit}\n") == brute(f"1\n{trial_prime} {trial_limit}\n")


def write(name, cases):
    text = str(len(cases)) + "\n"
    for prime, limit in cases:
        text += f"{prime} {limit}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 1), (999999937, 1), (999999937, 999999936), (2, 2), (3, 4)])
    write("3_wide", [(2, 10**18), (3, 10**18), (1000000007, 10**18), (999999999999999989, 10**18)])
    rng = random.Random(20261126)
    cases = []
    for _ in range(999):
        exponent_p = rng.randint(1, 60)
        exponent_n = rng.randint(1, 60)
        prime = min(rng.randint(2, 10 ** exponent_p), 10**18 - 1)
        limit = min(rng.randint(1, 10 ** exponent_n), 10**18 - 1)
        cases.append((prime, limit))
    write("4_random", cases)
    write("5_io", [(2, 10**18)] * 2000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
