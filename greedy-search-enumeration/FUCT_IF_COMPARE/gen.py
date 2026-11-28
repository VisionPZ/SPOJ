#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """5
9 2
-3 -5
5 28
0 0
19 13
"""
SAMPLE_OUTPUT = """9 is greater than 2
-3 is greater than -5
5 is smaller than 28
n is equal m: 0
19 is greater than 13
"""


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    lines = []
    cursor = 1
    for _ in range(count):
        first_value = int(parts[cursor])
        second_value = int(parts[cursor + 1])
        cursor += 2
        relation = (first_value > second_value) - (first_value < second_value)
        if relation > 0:
            line = "%d is greater than %d" % (first_value, second_value)
        elif relation < 0:
            line = "%d is smaller than %d" % (first_value, second_value)
        else:
            line = "n is equal m: %d" % first_value
        lines.append(line)
    return "\n".join(lines) + "\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        "%d %d\n" % (first_value, second_value) for first_value, second_value in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n5 5\n") == "n is equal m: 5\n"
assert oracle("1\n-3 -5\n") == "-3 is greater than -5\n"
assert oracle("1\n5 28\n") == "5 is smaller than 28\n"


def trace_example():
    for first_value, second_value in [(9, 2), (5, 28), (0, 0)]:
        relation = (first_value > second_value) - (first_value < second_value)
        print(first_value, second_value, relation)


def build():
    write("2_edges", [(-1000000000, 1000000000), (1000000000, -1000000000),
                      (0, 0), (-2147483648, 2147483647), (5, 5), (-1, -1)])
    large = [(1000000000, -1000000000), (-1000000000, 1000000000), (0, 0)]
    write("3_wide", (large * 334)[:1000])
    random.seed(2026)
    write("4_random", [(random.randint(-1000000000, 1000000000),
                        random.randint(-1000000000, 1000000000)) for _ in range(1000)])
    write("5_io", (large * 334)[:1000])


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(9, 2), (-3, -5), (5, 28), (0, 0), (19, 13)])
    build()
