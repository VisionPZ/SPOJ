#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for FUCT_IF_SQUARE.

The statement asks for one answer per test case, separated by a newline.
The printed sample misses the newline before its last answer; that is a typo
in the statement, not a formatting rule.  Every error message is one line.
"""
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """7
0
1
-2
3
12
-3
20
"""
SAMPLE_OUTPUT = (
    "the length of square's edge must be greater than 0\n"
    "4 1\n"
    "the length of square's edge must be greater than 0\n"
    "12 9\n"
    "48 144\n"
    "the length of square's edge must be greater than 0\n"
    "80 400\n"
)

STATEMENT_SAMPLE_OUTPUT = (
    "the length of square's edge must be greater than 0\n"
    "4 1\n"
    "the length of square's edge must be greater than 0\n"
    "12 9\n"
    "48 144\n"
    "the length of square's edge must be greater than 080 400\n"
)

ERROR_TEXT = "the length of square's edge must be greater than 0"


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    lines = []
    for case_index in range(count):
        edge = int(parts[case_index + 1])
        if edge <= 0:
            lines.append(ERROR_TEXT)
        else:
            lines.append("%d %d" % (4 * edge, edge * edge))
    return "".join(line + "\n" for line in lines)


def write(name, edges):
    input_text = str(len(edges)) + "\n" + "".join("%d\n" % edge for edge in edges)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert STATEMENT_SAMPLE_OUTPUT == SAMPLE_OUTPUT.replace(ERROR_TEXT + "\n80 400\n", ERROR_TEXT + "80 400\n")
assert oracle("1\n3\n") == "12 9\n"
assert oracle("1\n0\n") == ERROR_TEXT + "\n"
assert oracle("2\n0\n4\n") == ERROR_TEXT + "\n16 16\n"
assert oracle("3\n-1\n2\n-2\n") == ERROR_TEXT + "\n8 4\n" + ERROR_TEXT + "\n"


def trace_example():
    for edge in [0, 1, 3, 12, 20]:
        if edge <= 0:
            print(edge, ERROR_TEXT)
        else:
            print(edge, 4 * edge, edge * edge)


def build():
    write("2_edges", [0, 1, -1, 2, 100000, -100000, 7])
    write("3_wide", ([1000000, 999999, 0, -1] * 250)[:1000])
    random.seed(2026)
    write("4_random", [random.randint(-10000, 10000) for _ in range(1000)])
    write("5_io", ([999999999, 999999998, 1000000000] * 334)[:1000])


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [0, 1, -2, 3, 12, -3, 20])
    build()
