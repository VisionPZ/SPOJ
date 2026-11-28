#!/usr/bin/env python3
import random
from pathlib import Path

import numpy as np
from scipy.optimize import Bounds, LinearConstraint, milp

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = iter(text.split())
    datasets = []
    while True:
        height = int(next(tokens))
        width = int(next(tokens))
        if height == 0 and width == 0:
            break
        rows = [next(tokens) for _ in range(height)]
        datasets.append((rows, width))
    return datasets


def oracle(text):
    answers = []
    for rows, width in parse(text):
        height = len(rows)
        digits = [(r, c, int(rows[r][c]))
                  for r in range(height) for c in range(width)
                  if rows[r][c].isdigit()]
        candidates = [(r, c) for r in range(height) for c in range(width)
                      if rows[r][c] != '.' and
                      any(abs(r - dr) <= 1 and abs(c - dc) <= 1 for dr, dc, _ in digits)]
        matrix = np.zeros((len(digits), len(candidates)), dtype=float)
        for digit_index, (digit_row, digit_column, _) in enumerate(digits):
            for cell_index, (row, column) in enumerate(candidates):
                if abs(row - digit_row) <= 1 and abs(column - digit_column) <= 1:
                    matrix[digit_index, cell_index] = 1.0
        required = np.array([value for _, _, value in digits], dtype=float)
        result = milp(c=np.ones(len(candidates)),
                      integrality=np.ones(len(candidates)),
                      bounds=Bounds(0, 1),
                      constraints=LinearConstraint(matrix, required, required))
        answers.append(str(int(round(result.fun))))
    return "\n".join(answers) + "\n"


SAMPLE = """5 6
*2.2**
..*...
..2...
..*...
*2.2**
6 5
.*2*.
..*..
..*..
..2..
..*..
.*2*.
5 6
.1111.
**...*
33....
**...0
.*2**.
6 9
....1....
...1.1...
....1....
.1..*..1.
1.1***1.1
.1..*..1.
9 9
*********
*4*4*4*4*
*********
*4*4*4*4*
*********
*4*4*4*4*
*********
*4*4*4***
*********
0 0
"""
SAMPLE_OUT = """6
5
5
6
23
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0\n0 0\n") == "0\n"
assert oracle("1 1\n1\n0 0\n") == "1\n"
assert oracle("3 3\n***\n*0*\n***\n0 0\n") == "0\n"
assert oracle("3 3\n***\n*9*\n***\n0 0\n") == "9\n"


def render(datasets):
    lines = []
    for rows, width in datasets:
        lines.append(f"{len(rows)} {width}")
        lines.extend(rows)
    lines.append("0 0")
    return "\n".join(lines) + "\n"


def random_dataset(rng, height, width, digit_count):
    grid = [[rng.choice('.*.***') for _ in range(width)] for _ in range(height)]
    chests = [[1 if rng.random() < 0.3 else 0 for _ in range(width)] for _ in range(height)]
    positions = [(r, c) for r in range(height) for c in range(width)]
    rng.shuffle(positions)
    chosen = positions[:digit_count]
    for row, column in chosen:
        total = 0
        for near_row in range(max(0, row - 1), min(height, row + 2)):
            for near_column in range(max(0, column - 1), min(width, column + 2)):
                if grid[near_row][near_column] != '.':
                    total += chests[near_row][near_column]
        grid[row][column] = str(total)
    return (["".join(row) for row in grid], width)


def write(name, datasets):
    text = render(datasets)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        (["0"], 1),
        (["1"], 1),
        (["0*", "**"], 2),
        (["4*", "**"], 2),
    ])
    write("3_wide", [random_dataset(rng, 6, 6, 3) for _ in range(4)])
    write("4_random", [random_dataset(rng, rng.randint(2, 6), rng.randint(2, 6), rng.randint(1, 3))
                       for _ in range(10)])
    write("5_io", [random_dataset(rng, rng.randint(1, 3), rng.randint(1, 3), 1)
                   for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
