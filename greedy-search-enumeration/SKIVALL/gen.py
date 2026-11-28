#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def enumerate_best(grid):
    row_count = len(grid)
    column_count = len(grid[0])
    height = {(row, column): grid[row][column]
              for row in range(row_count) for column in range(column_count)}
    best_length = 0
    best_paths = set()
    for start in height:
        stack = [(start, (start,), 0)]
        while stack:
            current, path, phase = stack.pop()
            if len(path) > best_length:
                best_length = len(path)
                best_paths = {path}
            elif len(path) == best_length:
                best_paths.add(path)
            row, column = current
            for row_step, column_step in DIRECTIONS:
                neighbor = (row + row_step, column + column_step)
                if neighbor not in height or neighbor in path:
                    continue
                if phase == 0:
                    if height[neighbor] < height[current]:
                        stack.append((neighbor, path + (neighbor,), 0))
                    if height[neighbor] > height[current]:
                        stack.append((neighbor, path + (neighbor,), 1))
                elif height[neighbor] > height[current]:
                    stack.append((neighbor, path + (neighbor,), 1))
    canonical = set()
    for path in best_paths:
        if height[path[0]] > height[path[-1]]:
            path = tuple(reversed(path))
        canonical.add(tuple((row + 1, column + 1) for row, column in path))
    return best_length, canonical


def oracle(grid):
    length, paths = enumerate_best(grid)
    assert len(paths) == 1, (length, paths)
    path = next(iter(paths))
    lines = [str(length)] + [f"{row} {column}" for row, column in path]
    return "\n".join(lines) + "\n"


def encode(grid):
    header = f"{len(grid)} {len(grid[0])}\n"
    return header + "\n".join(" ".join(str(value) for value in row)
                              for row in grid) + "\n"


SAMPLE = """3 4
2 6 7 16
1 4 3 20
9 8 17 12
"""
SAMPLE_OUT = """9
3 1
3 2
2 2
2 1
1 1
1 2
1 3
1 4
2 4
"""
SAMPLE_GRID = [[2, 6, 7, 16], [1, 4, 3, 20], [9, 8, 17, 12]]
assert encode(SAMPLE_GRID) == SAMPLE
sample_length, sample_paths = enumerate_best(SAMPLE_GRID)
assert sample_length == 9
sample_path = tuple((int(row), int(column))
                    for row, column in (line.split() for line in SAMPLE_OUT.splitlines()[1:]))
assert sample_path in sample_paths
assert oracle([[7]]) == "1\n1 1\n"
assert oracle([[1, 2]]) == "2\n1 1\n1 2\n"


def unique_grid(rng, row_count, column_count):
    while True:
        values = list(range(row_count * column_count))
        rng.shuffle(values)
        grid = [values[index * column_count:(index + 1) * column_count]
                for index in range(row_count)]
        _, paths = enumerate_best(grid)
        if len(paths) == 1:
            return grid


def write(name, grid):
    text = encode(grid)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(grid))


def build():
    rng = random.Random(20261126)
    write("2_edges", unique_grid(rng, 1, 1))
    write("3_wide", unique_grid(rng, 3, 3))
    write("4_random", unique_grid(rng, 4, 4))
    write("5_io", unique_grid(rng, 4, 5))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
