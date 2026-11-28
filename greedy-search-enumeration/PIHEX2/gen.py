#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
HEX_CHARS = "0123456789ABCDEF"
TERMS = (1, 4, 5, 6)
COEFFS = (4, -2, -1, -1)


def bbp_digit(position):
    if position == 0:
        return "3"
    exponent = position - 1
    totals = [0.0, 0.0, 0.0, 0.0]
    for k in range(exponent + 1):
        for slot, term in enumerate(TERMS):
            modulus = 8 * k + term
            totals[slot] += COEFFS[slot] * pow(16, exponent - k, modulus) / modulus
    tail = 1.0 / 16.0
    for k in range(exponent + 1, exponent + 40):
        for slot, term in enumerate(TERMS):
            totals[slot] += COEFFS[slot] * tail / (8 * k + term)
        tail /= 16.0
    combined = sum(totals)
    fractional = combined - math.floor(combined)
    return HEX_CHARS[int(fractional * 16) % 16]


def exact_digit(position):
    if position == 0:
        return "3"
    exponent = position - 1
    total = Fraction(0)
    for k in range(exponent + 1):
        for slot, term in enumerate(TERMS):
            modulus = 8 * k + term
            total += Fraction(COEFFS[slot] * pow(16, exponent - k, modulus), modulus)
    for k in range(exponent + 1, exponent + 40):
        for slot, term in enumerate(TERMS):
            total += Fraction(COEFFS[slot], (8 * k + term) * 16 ** (k - exponent))
    total %= 1
    return HEX_CHARS[int(total * 16)]


def oracle(text):
    tokens = text.split()
    positions = [int(value) for value in tokens[1:1 + int(tokens[0])]]
    return "".join(bbp_digit(position) for position in positions) + "\n"


SAMPLE = """16
0 1 2 3 4 5 6 7 8 9 10 100 1000 10000 100000 1000000
"""
SAMPLE_OUT = """3243F6A8885C3652
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert bbp_digit(0) == "3"
assert bbp_digit(1) == "2"
assert bbp_digit(2) == "4"
assert bbp_digit(15) == "D"
assert all(exact_digit(position) == bbp_digit(position) for position in range(0, 40))
assert len(SAMPLE_OUT.strip()) == 16


def write_cases(name, positions):
    (ROOT / "in" / (name + ".txt")).write_text(str(len(positions)) + "\n" + " ".join(str(value) for value in positions) + "\n")
    (ROOT / "out" / (name + ".out")).write_text(oracle(str(len(positions)) + "\n" + " ".join(str(value) for value in positions) + "\n"))


def build():
    write_cases("2_edges", [0, 1, 2, 3, 15, 16, 255, 256])
    write_cases("3_wide", [1000000])
    rng = random.Random(20261126)
    write_cases("4_random", [rng.randint(0, 20000) for _ in range(20)])
    write_cases("5_io", [rng.randint(0, 2000) for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
