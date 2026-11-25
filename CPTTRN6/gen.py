#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    blocks = []
    for lines, columns, height, width in cases:
        total_cols = columns * (width + 1) + width
        grid = []
        for row in range(lines * (height + 1) + height):
            horizontal = (row + 1) % (height + 1) == 0
            chars = []
            for col in range(total_cols):
                boundary = (col + 1) % (width + 1) == 0
                if horizontal:
                    chars.append("+" if boundary else "-")
                else:
                    chars.append("|" if boundary else ".")
            grid.append("".join(chars))
        blocks.append("\n".join(grid) + "\n\n")
    return "".join(blocks)


SAMPLE = [(3, 1, 2, 1), (4, 4, 1, 2), (2, 5, 3, 2)]
SAMPLE_OUTPUT = r""".|.
.|.
-+-
.|.
.|.
-+-
.|.
.|.
-+-
.|.
.|.

..|..|..|..|..
--+--+--+--+--
..|..|..|..|..
--+--+--+--+--
..|..|..|..|..
--+--+--+--+--
..|..|..|..|..
--+--+--+--+--
..|..|..|..|..

..|..|..|..|..|..
..|..|..|..|..|..
..|..|..|..|..|..
--+--+--+--+--+--
..|..|..|..|..|..
..|..|..|..|..|..
..|..|..|..|..|..
--+--+--+--+--+--
..|..|..|..|..|..
..|..|..|..|..|..
..|..|..|..|..|..

"""
assert oracle(SAMPLE) == SAMPLE_OUTPUT
assert oracle([(1, 1, 1, 1)]) == ".|.\n-+-\n.|.\n\n"


def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(" ".join(str(value) for value in case) for case in cases)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


write("1_sample", SAMPLE)
write("2_edges", [(1, 1, 1, 1), (1, 1, 99, 99), (1, 99, 1, 1), (99, 1, 1, 1)])
write("3_wide", [(99, 99, 1, 1) for _ in range(8)])
random.seed(2026)
write("4_random", [(random.randint(1, 30), random.randint(1, 30),
                    random.randint(1, 30), random.randint(1, 30))
                   for _ in range(40)])
write("5_io", [(99, 99, 9, 9) for _ in range(8)])
