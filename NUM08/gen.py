#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_factors(value):
    factors = []
    divisor = 2
    rest = value
    while divisor * divisor <= rest:
        power = 0
        while rest % divisor == 0:
            rest //= divisor
            power += 1
        if power:
            factors.append((divisor, power))
        divisor += 1
    if rest > 1:
        factors.append((rest, 1))
    return factors


def brute_sigma(value):
    total = 1
    for prime, power in brute_factors(value):
        term = 1
        running = 1
        for _ in range(power):
            running *= prime
            term += running
        total *= term
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    blocks = []
    for value in tokens[1:1 + count]:
        lines = [f"{prime} {power}" for prime, power in brute_factors(value)]
        lines.append(f"Sum Of Divisiors: {brute_sigma(value)}")
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks) + "\n"


SAMPLE = """3
8
32
56
"""
SAMPLE_OUT = """2 3
Sum Of Divisiors: 15

2 5
Sum Of Divisiors: 63

2 3
7 1
Sum Of Divisiors: 120
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "2 1\nSum Of Divisiors: 3\n"
assert oracle("1\n1024\n") == "2 10\nSum Of Divisiors: 2047\n"
assert oracle("1\n12\n") == "2 2\n3 1\nSum Of Divisiors: 28\n"
assert brute_sigma(56) == 120 and brute_factors(56) == [(2, 3), (7, 1)]


def write(name, values):
    input_text = str(len(values)) + "\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [2, 4, 6, 12, 36, 100000])
    write("3_wide", [999999999998, 999999999990, 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23])
    rng = random.Random(20261126)
    values = []
    for _ in range(40):
        value = 2
        for _ in range(rng.randint(1, 5)):
            value *= rng.choice([2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31])
        values.append(value)
    write("4_random", values)
    wide = []
    base = 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 * 31 * 37
    for _ in range(100):
        wide.append(base)
    write("5_io", wide)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [8, 32, 56])
build()
