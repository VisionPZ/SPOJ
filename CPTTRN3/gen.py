#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    blocks = []
    for lines, columns in cases:
        full = "*" * (3 * columns + 1)
        inner = "*" + "..*" * columns
        rows = []
        for row in range(3 * lines + 1):
            rows.append(full if row % 3 == 0 else inner)
        blocks.append("\n".join(rows) + "\n\n")
    return "".join(blocks)


SAMPLE = [(3, 1), (4, 4), (2, 5)]
SAMPLE_OUT = '****\n*..*\n*..*\n****\n*..*\n*..*\n****\n*..*\n*..*\n****\n\n*************\n*..*..*..*..*\n*..*..*..*..*\n*************\n*..*..*..*..*\n*..*..*..*..*\n*************\n*..*..*..*..*\n*..*..*..*..*\n*************\n*..*..*..*..*\n*..*..*..*..*\n*************\n\n****************\n*..*..*..*..*..*\n*..*..*..*..*..*\n****************\n*..*..*..*..*..*\n*..*..*..*..*..*\n****************\n\n'
assert oracle(SAMPLE) == SAMPLE_OUT

def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(" ".join(str(value) for value in case) for case in cases)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


write("1_sample", SAMPLE)
write("2_edges", [(1, 1), (1, 99), (99, 1), (2, 2), (99, 99)])
random.seed(2026)
write("3_wide", [(random.randint(1, 99), random.randint(1, 99)) for _ in range(99)])
write("4_random", [(random.randint(1, 99), random.randint(1, 99)) for _ in range(99)])
write("5_io", [(99, 99) for _ in range(99)])
