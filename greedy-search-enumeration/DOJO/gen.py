#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def can_tile(rows, columns, hole_row, hole_column):
    hole = (hole_row - 1) * columns + (hole_column - 1)
    total_cells = rows * columns

    @lru_cache(maxsize=None)
    def search(position, mask):
        if position == total_cells:
            return mask == 0
        if position == hole:
            if mask & 1:
                return False
            return search(position + 1, mask >> 1)
        if mask & 1:
            return search(position + 1, mask >> 1)
        row, column = divmod(position, columns)
        if column + 1 < columns and position + 1 != hole and not (mask & 2):
            if search(position + 1, (mask >> 1) | 1):
                return True
        if row + 1 < rows and position + columns != hole:
            if search(position + 1, (mask >> 1) | 1):
                return True
        return False

    return search(0, 0)


def oracle(cases):
    answers = []
    for rows, columns, hole_row, hole_column in cases:
        answers.append("Possible." if can_tile(rows, columns, hole_row, hole_column)
                       else "Impossible.")
    return "\n".join(answers) + "\n"


def parity_rule(rows, columns, hole_row, hole_column):
    return (rows % 2 == 1 and columns % 2 == 1
            and (hole_row + hole_column) % 2 == 0)


SAMPLE_CASES = [(3, 3, 2, 2), (3, 3, 1, 2)]
SAMPLE = "2\n3 3 2 2\n3 3 1 2\n"
SAMPLE_OUT = "Possible.\nImpossible.\n"
assert oracle(SAMPLE_CASES) == SAMPLE_OUT
assert oracle([(1, 1, 1, 1)]) == "Possible.\n"
assert oracle([(2, 3, 1, 1)]) == "Impossible.\n"
assert oracle([(5, 5, 3, 3)]) == "Possible.\n"
for rows in range(1, 5):
    for columns in range(1, 5):
        for hole_row in range(1, rows + 1):
            for hole_column in range(1, columns + 1):
                assert can_tile(rows, columns, hole_row, hole_column) == parity_rule(
                    rows, columns, hole_row, hole_column)


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{rows} {columns} {hole_row} {hole_column}\n"
        for rows, columns, hole_row, hole_column in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def build():
    write("2_edges", [(1, 1, 1, 1), (1, 2, 1, 1), (2, 1, 2, 1),
                      (2, 2, 1, 1), (3, 3, 1, 1), (3, 3, 2, 3),
                      (4, 5, 2, 2), (5, 4, 3, 3)])
    rng = random.Random(20261126)
    cases = []
    for rows in range(1, 8):
        for columns in range(1, 8):
            for _ in range(4):
                cases.append((rows, columns, rng.randint(1, rows),
                              rng.randint(1, columns)))
    write("3_wide", cases)
    random_cases = []
    for _ in range(300):
        rows = rng.randint(1, 7)
        columns = rng.randint(1, 7)
        random_cases.append((rows, columns, rng.randint(1, rows),
                             rng.randint(1, columns)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20000):
        rows = rng.randint(1, 3)
        columns = rng.randint(1, 3)
        io_cases.append((rows, columns, rng.randint(1, rows),
                         rng.randint(1, columns)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
