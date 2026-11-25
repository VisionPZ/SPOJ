#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "5\n"
SAMPLE_OUT = """* * * * * * * * *
  * * * * * * *
    * * * * *
      * * *
        *
"""


def oracle_pyramid(height):
    if height <= 0:
        return "\n"
    width = 4 * height - 3
    canvas = [[" "] * width for _ in range(height)]
    for row in range(height):
        star_count = 2 * (height - row) - 1
        for star_index in range(star_count):
            canvas[row][2 * row + 2 * star_index] = "*"
    lines = ["".join(row).rstrip() for row in canvas]
    return "\n".join(lines) + "\n"


def oracle(input_text):
    tokens = input_text.split()
    answers = []
    for token in tokens:
        answers.append(oracle_pyramid(int(token)))
    return "".join(answers)


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    height = 5
    print("height 5, top row star count %d" % (2 * height - 1))
    print("row 1 leading spaces %d, star count %d" % (2, 2 * (height - 1) - 1))
    print("last row: %d spaces then one star" % (2 * (height - 1)))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("2\n") == "* * *\n  *\n"
assert oracle("1\n") == "*\n"
assert oracle("3\n") == "* * * * *\n  * * *\n    *\n"


def build():
    write("2_edges", "1\n2\n3\n4\n100\n")
    write("3_wide", "100\n99\n98\n")
    rng = random.Random(99)
    heights = [rng.randint(1, 100) for _ in range(200)]
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
