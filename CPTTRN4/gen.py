#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    blocks = []
    for lines, columns, cell_height, cell_width in cases:
        inner = "*" + ("." * cell_width + "*") * columns
        separator = "*" * len(inner)
        rows = []
        for row in range(lines * (cell_height + 1) + 1):
            rows.append(separator if row % (cell_height + 1) == 0 else inner)
        blocks.append("\n".join(rows) + "\n\n")
    return "".join(blocks)


SAMPLE = [(3, 1, 2, 1), (4, 4, 1, 2), (2, 5, 2, 2)]
SAMPLE_OUT = '***\n*.*\n*.*\n***\n*.*\n*.*\n***\n*.*\n*.*\n***\n\n*************\n*..*..*..*..*\n*************\n*..*..*..*..*\n*************\n*..*..*..*..*\n*************\n*..*..*..*..*\n*************\n\n****************\n*..*..*..*..*..*\n*..*..*..*..*..*\n****************\n*..*..*..*..*..*\n*..*..*..*..*..*\n****************\n\n'
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SAMPLE).startswith("***\n*.*\n*.*\n***")

def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(" ".join(str(value) for value in case) for case in cases)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


write("1_sample", SAMPLE)
write("2_edges", [(1, 1, 1, 1), (1, 99, 1, 1), (99, 1, 1, 1), (2, 2, 2, 2), (99, 99, 99, 99)])
random.seed(2026)
write("3_wide", [(random.randint(1, 20), random.randint(1, 20),
                  random.randint(1, 5), random.randint(1, 5)) for _ in range(99)])
write("4_random", [(random.randint(1, 20), random.randint(1, 20),
                    random.randint(1, 5), random.randint(1, 5)) for _ in range(99)])
write("5_io", [(20, 20, 5, 5) for _ in range(99)])
