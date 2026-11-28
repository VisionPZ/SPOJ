#!/usr/bin/env python3
import random
import sys
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """7
5 2
-15 -5
8 4
50 0
7 3
-6 2
18 -3
"""
SAMPLE_OUTPUT = """2.5
3
2
denominator cannot be zero
2.333333
-3
-6
"""


def trimmed(value):
    text = format(value, "f")
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return text


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    lines = []
    cursor = 1
    for _ in range(count):
        numerator = int(parts[cursor])
        denominator = int(parts[cursor + 1])
        cursor += 2
        if denominator == 0:
            lines.append("denominator cannot be zero")
            continue
        quotient = Decimal(numerator) / Decimal(denominator)
        rounded = quotient.quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)
        lines.append(trimmed(rounded))
    return "\n".join(lines) + "\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        "%d %d\n" % (numerator, denominator) for numerator, denominator in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1 3\n") == "0.333333\n"
assert oracle("1\n2 3\n") == "0.666667\n"
assert oracle("1\n-7 3\n") == "-2.333333\n"


def trace_example():
    for numerator, denominator in [(5, 2), (7, 3), (-15, -5), (50, 0)]:
        if denominator == 0:
            print(numerator, denominator, "denominator cannot be zero")
        else:
            quotient = Decimal(numerator) / Decimal(denominator)
            print(numerator, denominator, trimmed(
                quotient.quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)))


def build():
    write("2_edges", [(0, 5), (5, 0), (1, 3), (2, 3), (-1, 3), (1, -3),
                      (-15, -5), (8, 4), (1000000000, 3), (-1000000000, 7)])
    wide = [(1000000000, 3), (-1000000000, 7), (999999999, 9), (1, 2000000)]
    write("3_wide", (wide * 250)[:1000])
    random.seed(2026)
    random_pairs = []
    for _ in range(1000):
        denominator = random.randint(-1000000000, 1000000000)
        random_pairs.append((random.randint(-1000000000, 1000000000), denominator))
    write("4_random", random_pairs)
    write("5_io", (wide * 250)[:1000])


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(5, 2), (-15, -5), (8, 4), (50, 0), (7, 3), (-6, 2), (18, -3)])
    build()
