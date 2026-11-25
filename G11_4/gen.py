#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """1 9
12 321
5987 6123
12345678 12345679
0 0
"""
SAMPLE_OUTPUT = """0 1 1 1 1 1 1 1 1 1
61 169 163 83 61 61 61 61 61 61
134 58 28 24 23 36 147 24 27 47
0 2 2 2 2 2 2 2 1 1
"""


def count_one_digit(limit, digit):
    total = 0
    factor = 1
    while factor <= limit:
        higher = limit // (factor * 10)
        current = (limit // factor) % 10
        lower = limit % factor
        if digit != 0:
            if current > digit:
                total += (higher + 1) * factor
            elif current == digit:
                total += higher * factor + lower + 1
            else:
                total += higher * factor
        else:
            if higher == 0:
                break
            if current == 0:
                total += (higher - 1) * factor + lower + 1
            else:
                total += higher * factor
        factor *= 10
    return total


def oracle(text):
    parts = text.split()
    answers = []
    cursor = 0
    while cursor + 1 < len(parts):
        lower = int(parts[cursor]); upper = int(parts[cursor + 1])
        cursor += 2
        if lower == 0 and upper == 0:
            break
        counts = [count_one_digit(upper, d) - count_one_digit(lower - 1, d)
                  for d in range(10)]
        answers.append(" ".join(str(count) for count in counts))
    return "\n".join(answers) + "\n" if answers else ""


def write(name, pairs):
    input_text = "".join("%d %d\n" % pair for pair in pairs) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1 9\n0 0\n") == "0 1 1 1 1 1 1 1 1 1\n"
assert oracle("1 100\n0 0\n") == "11 21 20 20 20 20 20 20 20 20\n"
assert oracle("100 100\n0 0\n") == "2 1 0 0 0 0 0 0 0 0\n"
assert oracle("1 1\n0 0\n") == "0 1 0 0 0 0 0 0 0 0\n"


def trace_example():
    for upper in [9, 99, 100]:
        counts = [count_one_digit(upper, d) for d in range(10)]
        print(upper, " ".join(str(count) for count in counts))


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(1, 9), (12, 321), (5987, 6123), (12345678, 12345679)])
    write("2_edges", [(1, 1), (9, 10), (99, 100), (99999999, 100000000),
                      (1, 100000000), (100000000, 100000000)])
    random.seed(314159)
    write("3_wide", [(random.randint(1, 10**8), random.randint(1, 10**8))
                     for _ in range(40)])
    write("4_random", [(random.randint(1, 100000), random.randint(1, 100000))
                       for _ in range(150)])
    write("5_io", [(random.randint(1, 10**8), random.randint(1, 10**8))
                   for _ in range(2000)])
