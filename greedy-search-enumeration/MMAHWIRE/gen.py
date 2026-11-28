#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    datasets = []
    while cursor < len(tokens):
        rows = tokens[cursor]
        columns = tokens[cursor + 1]
        cursor += 2
        if rows == 0 and columns == 0:
            break
        grid = []
        for _ in range(rows):
            grid.append(tokens[cursor:cursor + columns])
            cursor += columns
        datasets.append(grid)
    return datasets


def oracle(text):
    answers = []
    for grid in parse(text):
        rows = len(grid)
        columns = len(grid[0])
        twos = []
        threes = []
        for row in range(rows):
            for column in range(columns):
                if grid[row][column] == 2:
                    twos.append((row, column))
                elif grid[row][column] == 3:
                    threes.append((row, column))
        if len(twos) != 2 or len(threes) != 2:
            answers.append(0)
            continue
        start, target = twos
        other_start, other_target = threes
        best = [None]

        def walk_second(position, used, length, first_length):
            if position == other_target:
                total = first_length + length
                if best[0] is None or total < best[0]:
                    best[0] = total
                return
            row, column = position
            for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                next_row = row + delta_row
                next_column = column + delta_column
                if not (0 <= next_row < rows and 0 <= next_column < columns):
                    continue
                cell = (next_row, next_column)
                if grid[next_row][next_column] in (1, 2) or cell in used:
                    continue
                walk_second(cell, used | {cell}, length + 1, first_length)

        def walk_first(position, used, length):
            if best[0] is not None and length >= best[0]:
                return
            if position == target:
                walk_second(other_start, used | {target}, 0, length)
                return
            row, column = position
            for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                next_row = row + delta_row
                next_column = column + delta_column
                if not (0 <= next_row < rows and 0 <= next_column < columns):
                    continue
                cell = (next_row, next_column)
                if cell != target and grid[next_row][next_column] != 0:
                    continue
                if cell in used:
                    continue
                walk_first(cell, used | {cell}, length + 1)

        walk_first(start, {start}, 0)
        answers.append(best[0] if best[0] is not None else 0)
    return "\n".join(str(value) for value in answers) + "\n"


SAMPLE_IN = """5 5
0 0 0 0 0
0 0 0 3 0
2 0 2 0 0
1 0 1 1 1
0 0 0 0 3
2 3
2 2 0
0 3 3
6 5
2 0 0 0 0
0 3 0 0 0
0 0 0 0 0
1 1 1 0 0
0 0 0 0 0
0 0 2 3 0
0 0
"""
SAMPLE_OUT = """18
2
17
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("2 3\n2 2 0\n0 3 3\n0 0\n") == "2\n"
assert oracle("2 2\n2 1\n3 3\n0 0\n") == "0\n"
assert oracle("2 3\n2 1 0\n3 3 2\n0 0\n") == "0\n"
assert oracle("2 4\n2 0 0 0\n0 0 3 3\n0 0\n") == "0\n"


def write(name, datasets):
    lines = []
    for grid in datasets:
        lines.append(f"{len(grid)} {len(grid[0])}")
        for row in grid:
            lines.append(" ".join(str(value) for value in row))
    lines.append("0 0")
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [
        [[2, 2, 0], [0, 3, 3]],
        [[2, 1], [3, 3]],
        [[2, 3], [3, 2]],
        [[2, 0, 0], [0, 3, 0], [0, 0, 2]],
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(3):
        grid = [[0] * 6 for _ in range(6)]
        positions = rng.sample(range(36), 6)
        for index in positions[:2]:
            grid[index // 6][index % 6] = 1
        for index in positions[2:4]:
            grid[index // 6][index % 6] = 2
        for index in positions[4:6]:
            grid[index // 6][index % 6] = 3
        wide.append(grid)
    write("3_wide", wide)
    random_grids = []
    for _ in range(12):
        rows = rng.randint(2, 5)
        columns = rng.randint(2, 5)
        grid = [[0] * columns for _ in range(rows)]
        positions = rng.sample(range(rows * columns), min(10, rows * columns))
        for index in positions[:max(0, len(positions) - 4)]:
            grid[index // columns][index % columns] = 1
        remaining = [index for index in range(rows * columns)
                     if grid[index // columns][index % columns] == 0]
        if len(remaining) < 4:
            continue
        chosen = rng.sample(remaining, 4)
        for index in chosen[:2]:
            grid[index // columns][index % columns] = 2
        for index in chosen[2:]:
            grid[index // columns][index % columns] = 3
        random_grids.append(grid)
    write("4_random", random_grids)
    io_grids = []
    for _ in range(100):
        grid = [[0] * 3 for _ in range(3)]
        grid[0][0] = 2
        grid[0][2] = 2
        grid[2][0] = 3
        grid[2][2] = 3
        io_grids.append(grid)
    write("5_io", io_grids)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
