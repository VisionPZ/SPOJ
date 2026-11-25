#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROMPT = "Please enter numerator: Please enter denominator: "


def oracle(text):
    numbers = [int(value) for value in text.split()]
    parts = []
    for pair_index in range(0, len(numbers), 2):
        numerator = numbers[pair_index]
        denominator = numbers[pair_index + 1]
        parts.append(PROMPT)
        if denominator == 0:
            parts.append("The denominator can't be zero!")
        else:
            negative = (numerator < 0) != (denominator < 0)
            magnitude = Fraction(abs(numerator), abs(denominator)) * 1000000
            rounded = (2 * magnitude.numerator + magnitude.denominator) // (2 * magnitude.denominator)
            digits = str(rounded).zfill(7)
            prefix = "-" if negative and rounded != 0 else ""
            parts.append(f"Result: {numerator} / {denominator} = {prefix}{digits[:-6]}.{digits[-6:]}")
        parts.append("\n")
    return "".join(parts)


SAMPLE = "7\n0\n"
SAMPLE_OUT = "Please enter numerator: Please enter denominator: The denominator can't be zero!\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("-8 -5\n") == "Please enter numerator: Please enter denominator: Result: -8 / -5 = 1.600000\n"
assert oracle("10 -2\n") == "Please enter numerator: Please enter denominator: Result: 10 / -2 = -5.000000\n"
assert oracle("1 4\n") == "Please enter numerator: Please enter denominator: Result: 1 / 4 = 0.250000\n"


def write(name, pairs):
    text = "".join(f"{numerator} {denominator}\n" for numerator, denominator in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0), (7, 0), (0, 5), (-8, -5), (10, -2), (1, 4), (-1, 3)])
    write("3_wide", [(1000000000, 3), (999999937, 7), (-1000000000, 6), (1, 1000000000)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(120):
        numerator = rng.randint(-1000000000, 1000000000)
        denominator = rng.randint(-1000, 1000)
        pairs.append((numerator, denominator))
    write("4_random", pairs)
    io_pairs = [(rng.randint(-1000000, 1000000), rng.choice([0, 1, -1, 2, -2, 3, 7])) for _ in range(1500)]
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(7, 0)])
build()
