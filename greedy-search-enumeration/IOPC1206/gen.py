#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def integer_root(value, exponent):
    if exponent == 1:
        return value
    low = 1
    high = 1000000
    while low <= high:
        middle = (low + high) // 2
        power = 1
        for _ in range(exponent):
            power *= middle
            if power > value:
                break
        if power <= value:
            low = middle + 1
        else:
            high = middle - 1
    return high


@lru_cache(maxsize=None)
def prefix(limit):
    if limit < 2:
        return 0
    total = 0
    exponent = 1
    while True:
        multiplier = 1
        while True:
            root = integer_root(limit // multiplier, exponent)
            if root <= multiplier:
                break
            total += root - multiplier
            multiplier += 1
        if multiplier == 1:
            break
        exponent += 1
    return total


def fair_direct(number, base):
    digit_count = 0
    remainder = number - 1
    while remainder:
        digit_count += 1
        remainder //= base
    if digit_count == 0:
        digit_count = 1
    counts = [[0] * base for _ in range(digit_count)]
    digits_of = []
    for value in range(number):
        digits = []
        rest = value
        for position in range(digit_count):
            digit = rest % base
            rest //= base
            digits.append(digit)
            counts[position][digit] += 1
        digits_of.append(digits)
    scores = set()
    for digits in digits_of:
        score = sum(counts[position][digits[position]]
                    for position in range(digit_count))
        scores.add(score)
    return len(scores) == 1


def fairness_factor(number):
    return sum(1 for base in range(2, number + 1) if fair_direct(number, base))


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    lines = []
    for _ in range(case_count):
        lower = tokens[cursor]
        upper = tokens[cursor + 1]
        cursor += 2
        lines.append(str(prefix(upper) - prefix(lower - 1)))
    return "\n".join(lines) + "\n"


SAMPLE = """2
4 8
20 30
"""
SAMPLE_OUT = """9
27
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert prefix(2) == 1 and prefix(3) == 2 and prefix(4) == 4
assert prefix(1000000) == 6999210
assert prefix(10 ** 12) == 13892875310980
for number in range(2, 150):
    assert prefix(number) - prefix(number - 1) == fairness_factor(number)


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(
        f"{lower} {upper}\n" for lower, upper in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 2), (2, 3), (3, 3), (4, 4),
                      (1000000, 1000000), (999999999999, 10 ** 12)])
    rng = random.Random(20261126)
    wide = []
    for _ in range(8):
        start = rng.randint(2, 10 ** 12 - 2000)
        wide.append((start, start + rng.randint(0, 2000)))
    write("3_wide", wide)
    random_pairs = []
    for _ in range(10):
        start = rng.randint(2, 10 ** 11)
        random_pairs.append((start, start + rng.randint(0, 500)))
    write("4_random", random_pairs)
    io_pairs = []
    for _ in range(20):
        start = rng.randint(2, 10 ** 12 - 100)
        io_pairs.append((start, start + rng.randint(0, 100)))
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
