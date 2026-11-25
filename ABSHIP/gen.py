#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.strip().split('\n')
    row_count, column_count, square_size = map(int, lines[0].split())
    grid = [list(line.strip()) for line in lines[1:1 + row_count]]
    component_id = [[-1] * column_count for _ in range(row_count)]
    component_count = 0
    for row in range(row_count):
        for col in range(column_count):
            if grid[row][col] != 'X' or component_id[row][col] != -1:
                continue
            component_id[row][col] = component_count
            queue = deque([(row, col)])
            while queue:
                current_row, current_col = queue.popleft()
                for delta_row, delta_col in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    next_row = current_row + delta_row
                    next_col = current_col + delta_col
                    if not (0 <= next_row < row_count and 0 <= next_col < column_count):
                        continue
                    if grid[next_row][next_col] != 'X' or component_id[next_row][next_col] != -1:
                        continue
                    component_id[next_row][next_col] = component_count
                    queue.append((next_row, next_col))
            component_count += 1
    total = 0
    for top in range(row_count - square_size + 1):
        for left in range(column_count - square_size + 1):
            seen = set()
            for row in range(top, top + square_size):
                for col in range(left, left + square_size):
                    if grid[row][col] == 'X':
                        seen.add(component_id[row][col])
            total += len(seen)
    squares = (row_count - square_size + 1) * (column_count - square_size + 1)
    scaled = (2 * total * 1000000 + squares) // (2 * squares)
    return f"{scaled // 1000000}.{scaled % 1000000:06d}\n"


SAMPLE = """5 5 2
XXXX.
X..X.
X..X.
X....
.XX..
"""
SAMPLE_OUT = """0.875000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 1\nX\n") == "1.000000\n"
assert oracle("2 2 2\nXX\nXX\n") == "1.000000\n"
assert oracle("3 3 1\nX.X\n...\nX.X\n") == "0.444444\n"
assert oracle("3 3 3\nXXX\nXXX\nXXX\n") == "1.000000\n"


def write(name, row_count, column_count, square_size, grid):
    text = f"{row_count} {column_count} {square_size}\n" + "\n".join(grid) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 2, 1, ["XX"])
    rng = random.Random(20261201)
    grid = ["".join("X" if rng.random() < 0.55 else "." for _ in range(40)) for _ in range(40)]
    write("3_wide", 40, 40, 20, grid)
    grid = ["".join("X" if rng.random() < 0.45 else "." for _ in range(30)) for _ in range(25)]
    write("4_random", 25, 30, 6, grid)
    write("5_io", 100, 100, 50, ["X" * 100 for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, 5, 2, ["XXXX.", "X..X.", "X..X.", "X....", ".XX.."])
build()
