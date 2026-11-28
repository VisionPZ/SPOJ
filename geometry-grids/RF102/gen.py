#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for RF102.

Each line lists house dimensions separated by commas.
The oracle folds math.gcd over the parsed numbers; the solution runs Euclid on byte-scanned values.
A line containing only zero ends the input.
"""
import random
import sys
from functools import reduce
from math import gcd
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2,3,4\n20,10\n1,2,3\n2,4,8,10\n0\n"
SAMPLE_OUTPUT = "1\n10\n1\n2\n"


def oracle(text):
    answers = []
    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if not stripped:
            continue
        if stripped == "0":
            break
        values = [int(token.strip()) for token in stripped.split(",")]
        answers.append(str(reduce(gcd, values)))
    return "".join(answer + "\n" for answer in answers)


def write(name, lines):
    input_text = "".join(",".join(str(value) for value in line) + "\n"
                         for line in lines) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert SAMPLE_OUTPUT == "1\n10\n1\n2\n"
assert reduce(gcd, [2, 3, 4]) == 1 and reduce(gcd, [20, 10]) == 10
assert reduce(gcd, [2, 4, 8, 10]) == 2 and reduce(gcd, [7]) == 7


def trace_example():
    for values in [[2, 3, 4], [20, 10], [1, 2, 3], [2, 4, 8, 10]]:
        print("%s -> gcd %d" % (
            ",".join(str(value) for value in values), reduce(gcd, values)))


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [[2, 3, 4], [20, 10], [1, 2, 3], [2, 4, 8, 10]])
    write("2_edges", [[7], [1, 1, 1], [0, 12], [1000000000, 1000000000],
                      [6, 9, 15], [13, 17]])
    write("3_wide", [[999999937, 999999929], [1000000000, 500000000, 250000000],
                     [2] * 40, list(range(1, 101))])
    random.seed(2026)
    write("4_random", [[random.randint(1, 1000000)
                        for _ in range(random.randint(1, 12))]
                       for _ in range(500)])
    write("5_io", [[random.randint(100000000, 999999999)
                    for _ in range(30)] for _ in range(5000)])
