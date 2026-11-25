#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    rows = int(tokens[0])
    columns = int(tokens[1])
    board = []
    position = 2
    for _ in range(rows):
        board.append(tokens[position])
        position += 1
    blocked = frozenset((row, column) for row, line in enumerate(board)
                        for column, mark in enumerate(line) if mark == 'X')
    all_cells = tuple((row, column) for row in range(rows) for column in range(columns))

    @lru_cache(maxsize=None)
    def search(index, occupied):
        while index < len(all_cells) and all_cells[index] in occupied:
            index += 1
        if index == len(all_cells):
            return 0
        row, column = all_cells[index]
        best = search(index + 1, occupied)
        if column + 4 <= columns:
            cells = frozenset((row, column + offset) for offset in range(4))
            if not cells & blocked and not cells & occupied:
                best = max(best, 1 + search(index + 1, occupied | cells))
        if row + 1 < rows and column + 1 < columns:
            cells = frozenset([(row, column), (row, column + 1),
                               (row + 1, column), (row + 1, column + 1)])
            if not cells & blocked and not cells & occupied:
                best = max(best, 1 + search(index + 1, occupied | cells))
        return best

    return str(search(0, frozenset())) + "\n"


SAMPLE = """4 5
X....
X..XX
X..XX
....X
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\nX\n") == "0\n"
assert oracle("2 2\n..\n..\n") == "1\n"
assert oracle("1 8\n........\n") == "2\n"
assert oracle("1 4\nXXXX\n") == "0\n"


def write(name, boards):
    text = str(len(boards[0])) + " " + str(len(boards[0][0])) + "\n"
    text += "\n".join("".join(row) for row in boards[0]) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    rng = random.Random(20261126)

    def board(rows, columns, density):
        return [[('X' if rng.random() < density else '.') for _ in range(columns)]
                for _ in range(rows)]

    write("2_edges", [["........", "........", "........", "........"]])
    write("3_wide", [board(8, 8, 0.18)])
    write("4_random", [board(rng.randint(1, 9), rng.randint(1, 9), rng.choice([0.0, 0.15, 0.35]))])
    write("5_io", [board(1, 22, 0.0)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
