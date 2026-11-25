#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n"
SAMPLE_OUT = """    *
  *   *
*       *
  *   *
    *
"""


def oracle_rhombus(side):
    if side <= 0:
        return "\n"
    row_count = 2 * side - 1
    width = 4 * side - 3
    canvas = [[" "] * width for _ in range(row_count)]
    for row in range(row_count):
        distance = min(row, row_count - 1 - row)
        canvas[row][2 * (side - 1 - distance)] = "*"
        canvas[row][2 * (side - 1) + 2 * distance] = "*"
    lines = ["".join(row).rstrip() for row in canvas]
    return "\n".join(lines) + "\n"


def oracle(input_text):
    tokens = input_text.split()
    answers = []
    for token in tokens:
        answers.append(oracle_rhombus(int(token)))
    return "".join(answers)


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    side = 3
    print("side 3, row count %d" % (2 * side - 1))
    print("middle row stars at columns 0 and %d" % (4 * side - 4))
    print("top row single star at column %d" % (2 * side - 2))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n") == "*\n"
assert oracle("2\n") == "  *\n*   *\n  *\n"
assert oracle("4\n") == "      *\n    *   *\n  *       *\n*           *\n  *       *\n    *   *\n      *\n"


def build():
    write("2_edges", "1\n2\n3\n4\n100\n")
    write("3_wide", "100\n99\n98\n")
    rng = random.Random(1001)
    sides = [rng.randint(1, 100) for _ in range(200)]
    write("4_random", "".join("%d\n" % s for s in sides))
    io_sides = [100] * 500
    write("5_io", "".join("%d\n" % s for s in io_sides))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_INPUT)
        build()
