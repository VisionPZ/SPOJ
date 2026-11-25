#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def forward(rows, columns, reach, pressed):
    grid = [[0] * columns for _ in range(rows)]
    for button_row, button_column in pressed:
        for cell_row in range(rows):
            for cell_column in range(columns):
                distance = abs(cell_row - button_row) + abs(cell_column - button_column)
                if distance <= reach:
                    grid[cell_row][cell_column] ^= 1
    return grid


def brute(rows, columns, reach, target):
    solutions = []
    for mask in range(1 << (rows * columns)):
        pressed = [(index // columns, index % columns)
                   for index in range(rows * columns) if (mask >> index) & 1]
        if forward(rows, columns, reach, pressed) == target:
            solutions.append(len(pressed))
    if len(solutions) != 1:
        raise ValueError("board without a unique press set")
    return solutions[0]


def oracle(case):
    rows, columns, reach, grid, expected = case
    if expected is not None:
        return expected
    return brute(rows, columns, reach, grid)


SAMPLE = """2
2 2 0
1 0
0 1
2 2 1
1 1
1 1
"""
SAMPLE_OUT = """2
4
"""
assert oracle((2, 2, 0, [[1, 0], [0, 1]], None)) == 2
assert oracle((2, 2, 1, [[1, 1], [1, 1]], None)) == 4
assert oracle((1, 1, 0, [[1]], None)) == 1
assert oracle((1, 1, 5, [[0]], None)) == 0
assert sum(sum(row) for row in forward(3, 3, 1, [(1, 1)])) == 5


def write_cases(name, cases):
    lines = [str(len(cases))]
    for rows, columns, reach, grid, _expected in cases:
        lines.append(f"{rows} {columns} {reach}")
        for row in grid:
            lines.append(" ".join(str(value) for value in row))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    answers = "\n".join(str(oracle(case)) for case in cases) + "\n"
    (ROOT / "out" / f"{name}.out").write_text(answers)


def build():
    write_cases("2_edges", [
        (1, 1, 0, [[1]], None),
        (1, 1, 5, [[0]], None),
        (2, 2, 0, [[1, 0], [0, 1]], None),
        (3, 3, 1, forward(3, 3, 1, [(1, 1)]), 1),
    ])
    rng = random.Random(20261126)
    grid = [[rng.randint(0, 1) for _ in range(20)] for _ in range(20)]
    write_cases("3_wide", [(20, 20, 0, grid, sum(sum(row) for row in grid))])
    random_cases = []
    while len(random_cases) < 6:
        rows = rng.randint(1, 3)
        columns = rng.randint(1, 3)
        reach = rng.randint(0, 2)
        pressed = [(rng.randrange(rows), rng.randrange(columns))
                   for _ in range(rng.randint(0, min(3, rows * columns)))]
        board = forward(rows, columns, reach, pressed)
        try:
            answer = brute(rows, columns, reach, board)
        except ValueError:
            continue
        random_cases.append((rows, columns, reach, board, answer))
    write_cases("4_random", random_cases)
    io_cases = []
    for _ in range(100):
        rows = 2
        columns = 2
        reach = rng.randint(0, 1)
        pressed = [(rng.randrange(rows), rng.randrange(columns)) for _ in range(2)]
        board = forward(rows, columns, reach, pressed)
        answer = brute(rows, columns, reach, board)
        io_cases.append((rows, columns, reach, board, answer))
    write_cases("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
