#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """7
0 9
2 5
1 -5
10 7
9 4
-9 4
12 20
"""
SAMPLE_OUTPUT = """the length of rectangular's edges must be greater than 0
14 10
the length of rectangular's edges must be greater than 0
34 70
26 36
the length of rectangular's edges must be greater than 0
64 240
"""

ERROR_TEXT = "the length of rectangular's edges must be greater than 0"


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    lines = []
    cursor = 1
    for _ in range(count):
        first_edge = int(parts[cursor])
        second_edge = int(parts[cursor + 1])
        cursor += 2
        if first_edge <= 0 or second_edge <= 0:
            lines.append(ERROR_TEXT)
        else:
            perimeter = first_edge + first_edge + second_edge + second_edge
            lines.append("%d %d" % (perimeter, first_edge * second_edge))
    return "\n".join(lines) + "\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        "%d %d\n" % (first_edge, second_edge) for first_edge, second_edge in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n2 5\n") == "14 10\n"
assert oracle("1\n0 5\n") == ERROR_TEXT + "\n"
assert oracle("1\n-1 -1\n") == ERROR_TEXT + "\n"


def trace_example():
    for first_edge, second_edge in [(0, 9), (2, 5), (10, 7), (12, 20)]:
        if first_edge <= 0 or second_edge <= 0:
            print(first_edge, second_edge, ERROR_TEXT)
        else:
            print(first_edge, second_edge,
                  first_edge + first_edge + second_edge + second_edge,
                  first_edge * second_edge)


def build():
    write("2_edges", [(0, 9), (1, 1), (-1, 2), (2, -1), (100000, 100000), (0, 0)])
    wide = [(1000000000, 1000000000), (999999999, 999999999), (0, 5), (5, 0)]
    write("3_wide", (wide * 250)[:1000])
    random.seed(2026)
    write("4_random", [(random.randint(-1000000000, 1000000000),
                        random.randint(-1000000000, 1000000000)) for _ in range(1000)])
    write("5_io", (wide * 250)[:1000])


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(0, 9), (2, 5), (1, -5), (10, 7), (9, 4), (-9, 4), (12, 20)])
    build()
