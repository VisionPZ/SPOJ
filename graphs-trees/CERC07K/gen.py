#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

KEY_BITS = {"b": 1, "y": 2, "r": 4, "g": 8,
            "B": 1, "Y": 2, "R": 4, "G": 8}


def parse(text):
    tokens = text.split()
    cursor = 0
    scenarios = []
    while cursor + 1 < len(tokens):
        rows = int(tokens[cursor]); cursor += 1
        columns = int(tokens[cursor]); cursor += 1
        if rows == 0 and columns == 0:
            break
        grid = []
        for _ in range(rows):
            grid.append(tokens[cursor][:columns]); cursor += 1
        scenarios.append(grid)
    return scenarios


def oracle_scenario(grid):
    rows = len(grid)
    columns = len(grid[0])
    start = None
    for row_index in range(rows):
        for column_index in range(columns):
            if grid[row_index][column_index] == "*":
                start = (row_index, column_index, 0)
    if start is None:
        return None
    distances = {start: 0}
    changed = True
    while changed:
        changed = False
        for (row_index, column_index, keys), distance in list(distances.items()):
            for delta_row, delta_column in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                next_row = row_index + delta_row
                next_column = column_index + delta_column
                if not (0 <= next_row < rows and 0 <= next_column < columns):
                    continue
                cell = grid[next_row][next_column]
                if cell == "#":
                    continue
                if cell in "BYRG" and not (keys & KEY_BITS[cell]):
                    continue
                next_keys = keys | KEY_BITS.get(cell, 0)
                next_state = (next_row, next_column, next_keys)
                candidate = distance + 1
                if candidate < distances.get(next_state, 10 ** 9):
                    distances[next_state] = candidate
                    changed = True
    exit_steps = [distance for (row_index, column_index, _), distance in distances.items()
                  if grid[row_index][column_index] == "X"]
    if not exit_steps:
        return None
    return min(exit_steps)


def oracle(text):
    answers = []
    for grid in parse(text):
        steps = oracle_scenario(grid)
        if steps is None:
            answers.append("The poor student is trapped!")
        else:
            answers.append(f"Escape possible in {steps} steps.")
    return "\n".join(answers) + "\n"


SAMPLE = """1 10
*........X

1 3
*#X

3 20
####################
#XY.gBr.*.Rb.G.GG.y#
####################

0 0
"""
SAMPLE_OUT = """Escape possible in 9 steps.
The poor student is trapped!
Escape possible in 45 steps.
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 2\n*X\n0 0\n") == "Escape possible in 1 steps.\n"
assert oracle("1 1\n*\n0 0\n") == "The poor student is trapped!\n"
assert oracle("1 6\n*bBy.X\n0 0\n") == "Escape possible in 5 steps.\n"
assert oracle("2 2\n*#\n#X\n0 0\n") == "The poor student is trapped!\n"


def write(name, grids):
    chunks = []
    for grid in grids:
        chunks.append(f"{len(grid)} {len(grid[0])}\n" + "\n".join(grid) + "\n\n")
    text = "".join(chunks) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [["*"], ["*X"], ["*#X"], ["*bBy.X"], ["X*"]])
    write("3_wide", [["*" + "." * 98 + "X"],
                     ["*" + "." * 49, "." * 50 + "X"],
                     ["*" + "#" * 99]])
    rng = random.Random(20261126)
    random_grids = []
    for _ in range(25):
        rows = rng.randint(1, 8)
        columns = rng.randint(1, 8)
        alphabet = ".#" + "byrgBYRG" + "X"
        grid = ["".join(rng.choice(alphabet) for _ in range(columns))
                for _ in range(rows)]
        start_row = rng.randrange(rows)
        start_column = rng.randrange(columns)
        row_chars = list(grid[start_row])
        row_chars[start_column] = "*"
        grid[start_row] = "".join(row_chars)
        random_grids.append(grid)
    write("4_random", random_grids)
    io_grids = []
    for index in range(10000):
        variant = index % 4
        if variant == 0:
            io_grids.append(["*X."])
        elif variant == 1:
            io_grids.append(["*bB"])
        elif variant == 2:
            io_grids.append(["#*X"])
        else:
            io_grids.append([".*X"])
    write("5_io", io_grids)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
