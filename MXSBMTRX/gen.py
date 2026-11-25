#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def largest_increasing(matrix):
    rows = len(matrix)
    columns = len(matrix[0])
    row_bad = [[0] * columns for _ in range(rows)]
    column_bad = [[0] * columns for _ in range(rows)]
    for row in range(rows):
        for column in range(columns):
            if column > 0 and matrix[row][column - 1] >= matrix[row][column]:
                row_bad[row][column] = 1
            if row > 0 and matrix[row - 1][column] >= matrix[row][column]:
                column_bad[row][column] = 1
    row_prefix = [[0] * (columns + 1) for _ in range(rows + 1)]
    column_prefix = [[0] * (columns + 1) for _ in range(rows + 1)]
    for row in range(rows):
        for column in range(columns):
            row_prefix[row + 1][column + 1] = (row_prefix[row][column + 1]
                                               + row_prefix[row + 1][column]
                                               - row_prefix[row][column]
                                               + row_bad[row][column])
            column_prefix[row + 1][column + 1] = (column_prefix[row][column + 1]
                                                  + column_prefix[row + 1][column]
                                                  - column_prefix[row][column]
                                                  + column_bad[row][column])
    best = 0
    for top in range(rows):
        for left in range(columns):
            for bottom in range(top, rows):
                for right in range(left, columns):
                    row_violations = (row_prefix[bottom + 1][right + 1]
                                      - row_prefix[top][right + 1]
                                      - row_prefix[bottom + 1][left + 1]
                                      + row_prefix[top][left + 1])
                    column_violations = (column_prefix[bottom + 1][right + 1]
                                         - column_prefix[top + 1][right + 1]
                                         - column_prefix[bottom + 1][left]
                                         + column_prefix[top + 1][left])
                    if row_violations == 0 and column_violations == 0:
                        area = (bottom - top + 1) * (right - left + 1)
                        if area > best:
                            best = area
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        rows = tokens[position]
        columns = tokens[position + 1]
        position += 2
        matrix = [tokens[position + index * columns:position + (index + 1) * columns]
                  for index in range(rows)]
        position += rows * columns
        answers.append(str(largest_increasing(matrix)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
2 3
2 2 2
2 2 2
3 3
1 2 5
4 6 7
10 8 3
"""
SAMPLE_OUT = """1
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n7\n") == "1\n"
assert oracle("1\n1 5\n1 2 3 4 5\n") == "5\n"
assert oracle("1\n5 1\n1\n2\n3\n4\n5\n") == "5\n"
assert oracle("1\n1 5\n5 4 3 2 1\n") == "1\n"
assert oracle("1\n2 2\n-5 -4\n-3 -2\n") == "4\n"
assert oracle("1\n3 4\n10 10 10 10\n10 1 2 10\n10 3 4 10\n") == "4\n"


def write_cases(name, matrices):
    lines = [str(len(matrices))]
    for matrix in matrices:
        lines.append(f"{len(matrix)} {len(matrix[0])}")
        for row in matrix:
            lines.append(" ".join(str(value) for value in row))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_cases("2_edges", [
        [[7]],
        [[1, 2, 3, 4, 5]],
        [[1], [2], [3], [4], [5]],
        [[5, 4, 3, 2, 1]],
        [[2, 2, 2], [2, 2, 2]],
        [[-5, -4], [-3, -2]],
        [[3, 2], [1, 0]],
    ])
    rng = random.Random(20261126)
    wide = [[[row * 20 + column + rng.randint(-2, 2) for column in range(200)]
             for row in range(3)]]
    write_cases("3_wide", wide)
    random_matrices = []
    for _ in range(30):
        rows = rng.randint(1, 8)
        columns = rng.randint(1, 8)
        random_matrices.append([[rng.randint(-50, 50) for _ in range(columns)]
                                for _ in range(rows)])
    write_cases("4_random", random_matrices)
    io_matrices = []
    for _ in range(50):
        io_matrices.append([[rng.randint(-1000000000, 1000000000) for _ in range(4)]
                            for _ in range(4)])
    write_cases("5_io", io_matrices)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_cases("1_sample", [
    [[2, 2, 2], [2, 2, 2]],
    [[1, 2, 5], [4, 6, 7], [10, 8, 3]],
])
build()
