#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """5
-7
9
0
4
-3
"""
SAMPLE_OUTPUT = (
    "-7 is negative number \n"
    "9 is positive number \n"
    "n is zero \n"
    "4 is positive number \n"
    "-3 is negative number\n"
)


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    lines = []
    for case_index in range(count):
        value = int(parts[case_index + 1])
        if value < 0:
            line = "%d is negative number" % value
        elif value > 0:
            line = "%d is positive number" % value
        else:
            line = "n is zero"
        if case_index + 1 < count:
            line += " "
        lines.append(line)
    return "\n".join(lines) + "\n"


def write(name, numbers):
    input_text = str(len(numbers)) + "\n" + "".join("%d\n" % number for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n0\n") == "n is zero\n"
assert oracle("2\n1\n2\n") == "1 is positive number \n2 is positive number\n"
assert oracle("2\n-1\n-2\n") == "-1 is negative number \n-2 is negative number\n"


def trace_example():
    for value in [-7, 9, 0]:
        if value < 0:
            print(value, "negative")
        elif value > 0:
            print(value, "positive")
        else:
            print(0, "zero")


def build():
    write("2_edges", [-1000000, 1000000, 0, -1, 1, -999999, 999999])
    write("3_wide", ([1000000, -1000000, 0] * 334)[:1000])
    random.seed(2026)
    write("4_random", [random.randint(-1000000, 1000000) for _ in range(1000)])
    write("5_io", ([1000000, -1000000, 0] * 334)[:1000])


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [-7, 9, 0, 4, -3])
    build()
