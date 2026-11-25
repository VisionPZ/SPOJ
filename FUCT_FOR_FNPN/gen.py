#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """4
5
8
1
0
"""
SAMPLE_OUTPUT = """1 2 3 4 5
1 2 3 4 5 6 7 8
1
invalid
"""


def oracle(text):
    parts = text.split()
    count = int(parts[0])
    answers = []
    for index in range(1, count + 1):
        upper = int(parts[index])
        if upper <= 0:
            answers.append("invalid")
        else:
            answers.append(" ".join(str(value) for value in range(1, upper + 1)))
    return "\n".join(answers) + "\n"


def write(name, limits):
    input_text = str(len(limits)) + "\n" + "".join("%d\n" % limit for limit in limits)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1\n") == "1\n"
assert oracle("2\n0\n-3\n") == "invalid\ninvalid\n"
assert oracle("1\n10\n") == "1 2 3 4 5 6 7 8 9 10\n"


def trace_example():
    for upper in [1, 5, 0]:
        if upper <= 0:
            print(upper, "invalid")
        else:
            print(upper, " ".join(str(value) for value in range(1, upper + 1)))


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [5, 8, 1, 0])
    write("2_edges", [1, 2, 3, 0, 9, 10, 100])
    write("3_wide", [2000, 1999, 2001, 0, 1234])
    random.seed(271828)
    write("4_random", [random.randint(0, 700) for _ in range(120)])
    write("5_io", [random.randint(1, 3000) for _ in range(150)])
