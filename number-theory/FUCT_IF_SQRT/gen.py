#!/usr/bin/env python3
import random
import sys
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """7
4
7
0
2
-9
1
-3
"""
SAMPLE_OUTPUT = """2
2.645751
0 
1.414214
invalid
1
invalid
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
    for case_index in range(count):
        number = int(parts[case_index + 1])
        if number < 0:
            lines.append("invalid")
            continue
        root = Decimal(number).sqrt()
        rounded = root.quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)
        line = trimmed(rounded)
        if number == 0:
            line += " "
        lines.append(line)
    return "\n".join(lines) + "\n"


def write(name, numbers):
    input_text = str(len(numbers)) + "\n" + "".join("%d\n" % number for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n4\n") == "2\n"
assert oracle("1\n2\n") == "1.414214\n"
assert oracle("1\n-1\n") == "invalid\n"


def trace_example():
    for number in [4, 7, 0, 2]:
        root = Decimal(number).sqrt()
        print(number, trimmed(root.quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 999999, 1000000, -1, -999999])
    wide = [1000000, 999999, 999998, 2, 3]
    write("3_wide", (wide * 200)[:1000])
    random.seed(2026)
    write("4_random", [random.randint(-10, 1000000) for _ in range(1000)])
    write("5_io", (wide * 200)[:1000])


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [4, 7, 0, 2, -9, 1, -3])
    build()
