#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.strip().split('\n')
    row_count, column_count, square_size = map(int, lines[0].split())
    grid = [line.strip() for line in lines[1:1 + row_count]]
    prefix = [[0] * (column_count + 1) for _ in range(row_count + 1)]
    for row in range(row_count):
        for col in range(column_count):
            prefix[row + 1][col + 1] = (prefix[row][col + 1] + prefix[row + 1][col]
                                        - prefix[row][col] + (grid[row][col] == 'X'))
    total = 0
    for top in range(row_count - square_size + 1):
        for left in range(column_count - square_size + 1):
            total += (prefix[top + square_size][left + square_size]
                      - prefix[top][left + square_size]
                      - prefix[top + square_size][left]
                      + prefix[top][left])
    squares = (row_count - square_size + 1) * (column_count - square_size + 1)
    scaled = (2 * total * 1000000 + squares) // (2 * squares)
    return f"{scaled // 1000000}.{scaled % 1000000:06d}\n"


def coverage_oracle(text):
    lines = text.strip().split('\n')
    row_count, column_count, square_size = map(int, lines[0].split())
    grid = [line.strip() for line in lines[1:1 + row_count]]
    total = 0
    for row in range(row_count):
        rows = max(0, row - square_size + 1)
        row_end = min(row, row_count - square_size)
        for col in range(column_count):
            if grid[row][col] != 'X':
                continue
            cols = max(0, col - square_size + 1)
            col_end = min(col, column_count - square_size)
            total += (row_end - rows + 1) * (col_end - cols + 1)
    squares = (row_count - square_size + 1) * (column_count - square_size + 1)
    scaled = (2 * total * 1000000 + squares) // (2 * squares)
    return f"{scaled // 1000000}.{scaled % 1000000:06d}\n"


SAMPLE = """3 4 2
XX.X
XX..
.X..
"""
SAMPLE_OUT = """2.000000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert coverage_oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 1\nX\n") == "1.000000\n"
assert oracle("2 2 2\nXX\nXX\n") == "4.000000\n"
assert oracle("2 3 1\nX.X\n...\n") == "0.333333\n"
TINY = "4 5 2\nXX..X\n.X.X.\n....X\nX...X\n"
assert oracle(TINY) == coverage_oracle(TINY)


def write(name, row_count, column_count, square_size, grid):
    text = f"{row_count} {column_count} {square_size}\n" + "\n".join(grid) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2, 2, 1, [".X", "X."])
    write("3_wide", 60, 60, 1, ["X." * 30 for _ in range(60)])
    rng = random.Random(20261129)
    grid = ["".join("X" if rng.random() < 0.37 else "." for _ in range(60)) for _ in range(50)]
    write("4_random", 50, 60, 7, grid)
    write("5_io", 300, 300, 150, ["X" * 300 for _ in range(300)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, 4, 2, ["XX.X", "XX..", ".X.."])
build()
