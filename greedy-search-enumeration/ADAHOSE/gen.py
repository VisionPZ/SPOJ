#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    field_size = tokens[0]
    values = tokens[1:]
    grid = [values[row * field_size:(row + 1) * field_size]
            for row in range(field_size)]
    infinite = 10 ** 18
    distances = [[infinite] * field_size for _ in range(field_size)]
    for row in range(field_size):
        distances[row][0] = grid[row][0]
    for _ in range(field_size * field_size):
        changed = False
        for row in range(field_size):
            for column in range(field_size):
                for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    next_row = row + delta_row
                    next_column = column + delta_column
                    if not (0 <= next_row < field_size and 0 <= next_column < field_size):
                        continue
                    candidate = distances[row][column] + grid[next_row][next_column]
                    if candidate < distances[next_row][next_column]:
                        distances[next_row][next_column] = candidate
                        changed = True
        if not changed:
            break
    return str(2 * min(distances[row][field_size - 1] for row in range(field_size))) + "\n"


SAMPLE = """3
9 3 2
1 9 3
3 3 9
"""
SAMPLE_OUT = """26
"""
SECOND = """4
2 0 0 2
0 2 2 0
2 0 0 2
0 2 2 0
"""
SECOND_OUT = """8
"""
THIRD = """8
2 2 0 1 2 1 5 1
5 1 3 7 1 6 3 1
3 8 5 3 6 6 8 8
2 9 6 6 8 2 3 0
5 4 3 9 7 1 0 4
2 5 1 5 2 5 6 5
5 3 8 3 9 8 1 1
8 9 0 8 2 3 1 9
"""
THIRD_OUT = """28
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == SECOND_OUT
assert oracle(THIRD) == THIRD_OUT
assert oracle("1\n5\n") == "10\n"
assert oracle("2\n0 0\n0 0\n") == "0\n"


def write(name, grid):
    text = f"{len(grid)}\n" + "".join(
        " ".join(str(value) for value in row) + "\n" for row in grid)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0, 5], [7, 0]])
    write("3_wide", [[1000] * 6 for _ in range(6)])
    rng = random.Random(20261126)
    write("4_random", [[rng.randint(0, 1000) for _ in range(7)] for _ in range(7)])
    write("5_io", [[rng.randint(0, 20) for _ in range(8)] for _ in range(8)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[9, 3, 2], [1, 9, 3], [3, 3, 9]])
build()
