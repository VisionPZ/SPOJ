#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent

ZERO_TEXT = "the denominator can not be zero\n"

SAMPLE_INPUT = """8
-8 16
1 9
8 10
-3 0
150 200
-9 -12
27 9
45 -50
"""
SAMPLE_OUT = """-1 2
1 9
4 5
the denominator can not be zero
3 4
3 4
3
-9 10
"""


def format_fraction(value):
    if value.denominator == 1:
        return "%d\n" % value.numerator
    return "%d %d\n" % (value.numerator, value.denominator)


def oracle(input_text):
    tokens = input_text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        numerator = int(tokens[cursor])
        denominator = int(tokens[cursor + 1])
        cursor += 2
        if denominator == 0:
            answers.append(ZERO_TEXT)
        else:
            answers.append(format_fraction(Fraction(numerator, denominator)))
    return "".join(answers)


def write(name, cases):
    input_text = "%d\n" % len(cases) + "".join("%d %d\n" % pair for pair in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    numerator, denominator = -8, 16
    divisor = 8
    print("pair -8 16")
    print("gcd of absolute values %d" % divisor)
    print("reduced -1 2, sign kept on top")


SAMPLE = [(-8, 16), (1, 9), (8, 10), (-3, 0), (150, 200), (-9, -12), (27, 9), (45, -50)]

assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n0 5\n") == "0\n"
assert oracle("1\n7 -3\n") == "-7 3\n"
assert oracle("1\n-6 -6\n") == "1\n"


def build():
    write("2_edges", [
        (0, 1), (0, -7), (5, 1), (-5, 1), (7, -3), (-6, -6),
        (1, -1), (1000000000, 1000000000), (-9223372036854775807, 3),
        (9223372036854775807, 9223372036854775807), (0, 0), (12, 0),
    ])
    write("3_wide", [
        (9223372036854775807, 9223372036854775806),
        (-9223372036854775807, 9223372036854775807),
        (1099511627776, 1099511627775),
        (2 ** 62, 2 ** 61),
        (-45, -50), (150, 200),
    ])
    rng = random.Random(777)
    random_cases = []
    for _ in range(1000):
        numerator = rng.randint(-10 ** 18, 10 ** 18)
        denominator = rng.randint(-10 ** 18, 10 ** 18)
        if denominator == 0:
            denominator = 1
        random_cases.append((numerator, denominator))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(1000):
        numerator = rng.randint(-10 ** 18, 10 ** 18)
        denominator = rng.randint(1, 10 ** 18)
        io_cases.append((numerator, denominator))
    write("5_io", io_cases)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE)
        build()
