#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

INVALID_TEXT = "accept positive integer greater than 2 only!\n"

SAMPLE_INPUT = "5\n"
SAMPLE_OUT = "* * * * *\n  *       *\n    *       *\n  *       *\n* * * * *\n"


def oracle_arrow(height):
    if height <= 2:
        return INVALID_TEXT
    mid_distance = (height - 1) // 2
    width = 2 * height - 2 + 2 * mid_distance + 1
    canvas = [[" "] * width for _ in range(height)]
    for column in range(0, 2 * height - 1, 2):
        canvas[0][column] = "*"
        canvas[height - 1][column] = "*"
    for row in range(height):
        distance = min(row, height - 1 - row)
        canvas[row][2 * distance] = "*"
        canvas[row][2 * distance + 2 * height - 2] = "*"
    lines = ["".join(row).rstrip() for row in canvas]
    return "\n".join(lines) + "\n"


def oracle(input_text):
    tokens = input_text.split()
    answers = []
    for token in tokens:
        answers.append(oracle_arrow(int(token)))
    return "".join(answers)


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    height = 5
    mid = (height - 1) // 2
    print("height 5, middle row index %d" % mid)
    print("row 1 stars at columns 2 and %d" % (2 + 2 * height - 2))
    print("gap between them %d spaces" % (2 * height - 3))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("2\n") == INVALID_TEXT
assert oracle("3\n") == "* * *\n  *   *\n* * *\n"
assert oracle("1\n") == INVALID_TEXT
assert oracle("4\n") == "* * * *\n  *     *\n  *     *\n* * * *\n"


def build():
    write("2_edges", "1\n2\n3\n4\n100\n")
    write("3_wide", "100\n99\n98\n")
    rng = random.Random(42)
    heights = [rng.randint(3, 100) for _ in range(200)]
    write("4_random", "".join("%d\n" % h for h in heights))
    io_heights = [100] * 500
    write("5_io", "".join("%d\n" % h for h in io_heights))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_INPUT)
        build()
