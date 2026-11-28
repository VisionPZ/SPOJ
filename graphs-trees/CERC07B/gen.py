#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

DIRECTIONS = ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1))


def oracle_scenario(rows):
    row_count = len(rows)
    column_count = len(rows[0])
    variable_count = row_count * column_count
    tap_effects = []
    for row_index in range(row_count):
        for column_index in range(column_count):
            effect = 0
            for delta_row, delta_column in DIRECTIONS:
                next_row = row_index + delta_row
                next_column = column_index + delta_column
                if 0 <= next_row < row_count and 0 <= next_column < column_count:
                    effect |= 1 << (next_row * column_count + next_column)
            tap_effects.append(effect)
    equations = []
    for cell_index in range(variable_count):
        coefficients = 0
        for variable_index, effect in enumerate(tap_effects):
            if (effect >> cell_index) & 1:
                coefficients |= 1 << variable_index
        row_index = cell_index // column_count
        column_index = cell_index % column_count
        right_side = 1 if rows[row_index][column_index] == "X" else 0
        equations.append([coefficients, right_side])
    pivots = []
    pivot_index = 0
    for column_index in range(variable_count):
        pivot = None
        for equation_index in range(pivot_index, len(equations)):
            if (equations[equation_index][0] >> column_index) & 1:
                pivot = equation_index
                break
        if pivot is None:
            continue
        equations[pivot_index], equations[pivot] = equations[pivot], equations[pivot_index]
        for equation_index in range(len(equations)):
            if equation_index != pivot_index and ((equations[equation_index][0] >> column_index) & 1):
                equations[equation_index][0] ^= equations[pivot_index][0]
                equations[equation_index][1] ^= equations[pivot_index][1]
        pivots.append(column_index)
        pivot_index += 1
    for coefficients, right_side in equations:
        if coefficients == 0 and right_side == 1:
            return None
    free_columns = [column for column in range(variable_count) if column not in pivots]
    best = None
    for combination in range(1 << len(free_columns)):
        solution = 0
        for free_index, column_index in enumerate(free_columns):
            if (combination >> free_index) & 1:
                solution |= 1 << column_index
        for equation_index, column_index in enumerate(pivots):
            coefficients, right_side = equations[equation_index]
            parity = right_side ^ (bin(coefficients & solution).count("1") & 1)
            if parity:
                solution |= 1 << column_index
        weight = bin(solution).count("1")
        if best is None or weight < best:
            best = weight
    return best


def parse(text):
    tokens = text.split()
    cursor = 0
    scenarios = []
    while cursor + 1 < len(tokens):
        rows = int(tokens[cursor]); cursor += 1
        columns = int(tokens[cursor]); cursor += 1
        if rows == 0 and columns == 0:
            break
        board = []
        for _ in range(rows):
            board.append(tokens[cursor][:columns]); cursor += 1
        scenarios.append(board)
    return scenarios


def oracle(text):
    answers = []
    for board in parse(text):
        taps = oracle_scenario(board)
        if taps is None:
            answers.append("Damaged billboard.")
        else:
            answers.append(f"You have to tap {taps} tiles.")
    return "\n".join(answers) + "\n"


SAMPLE = """5 5
XX.XX
X.X.X
.XXX.
X.X.X
XX.XX

5 5
.XX.X
.....
..XXX
..X.X
..X..

1 5
...XX

5 5
...X.
...XX
.XX..
..X..
.....

8 9
..XXXXX..
.X.....X.
X..X.X..X
X.......X
X.X...X.X
X..XXX..X
.X.....X.
..XXXXX..

0 0
"""
SAMPLE_OUT = """You have to tap 5 tiles.
Damaged billboard.
You have to tap 1 tiles.
You have to tap 2 tiles.
You have to tap 25 tiles.
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n.\n0 0\n") == "You have to tap 0 tiles.\n"
assert oracle("1 1\nX\n0 0\n") == "You have to tap 1 tiles.\n"
assert oracle("1 2\nXX\n0 0\n") == "You have to tap 1 tiles.\n"
assert oracle("1 2\nX.\n0 0\n") == "Damaged billboard.\n"


def write(name, boards):
    chunks = []
    for board in boards:
        chunks.append(f"{len(board)} {len(board[0])}\n" + "\n".join(board) + "\n\n")
    text = "".join(chunks) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[".", ".", "."], ["X"], ["XX"], ["..", ".."], ["X.", ".."]])
    write("3_wide", [
        ["..XXXXX..", ".X.....X.", "X..X.X..X", "X.......X",
         "X.X...X.X", "X..XXX..X", ".X.....X.", "..XXXXX.."],
        ["XXXX", "XXXX", "XXXX", "XXXX"],
        ["X.X.", ".X.X", "X.X.", ".X.X"],
    ])
    rng = random.Random(20261124)
    random_boards = []
    for _ in range(20):
        rows = rng.randint(1, 4)
        columns = rng.randint(1, 4)
        random_boards.append(["".join(rng.choice("X.") for _ in range(columns))
                              for _ in range(rows)])
    write("4_random", random_boards)
    io_boards = []
    for index in range(3000):
        columns = 1 + index % 3
        io_boards.append(["".join("X" if (index + position) % 3 == 0 else "."
                                  for position in range(columns))])
    write("5_io", io_boards)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
