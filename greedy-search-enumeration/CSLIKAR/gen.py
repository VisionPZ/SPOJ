#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """3 6
D...*.
.X.X..
....S.
"""
SAMPLE_OUT = """6
"""


def neighbours(cell, rows, columns):
    row, column = divmod(cell, columns)
    if row > 0:
        yield cell - columns
    if row + 1 < rows:
        yield cell + columns
    if column > 0:
        yield cell - 1
    if column + 1 < columns:
        yield cell + 1


def oracle(text):
    lines = text.splitlines()
    rows, columns = (int(value) for value in lines[0].split())
    grid = []
    for row_index in range(rows):
        row = lines[1 + row_index]
        grid.extend(row[:columns])
    water = set()
    hedgehogs = set()
    for cell, symbol in enumerate(grid):
        if symbol == '*':
            water.add(cell)
        elif symbol == 'S':
            hedgehogs.add(cell)
    visited = set(hedgehogs)
    minute = 0
    while hedgehogs:
        new_water = set()
        for cell in water:
            for neighbour_cell in neighbours(cell, rows, columns):
                if grid[neighbour_cell] in 'XD':
                    continue
                if neighbour_cell not in water:
                    new_water.add(neighbour_cell)
        water.update(new_water)
        minute += 1
        new_hedgehogs = set()
        for cell in hedgehogs:
            for neighbour_cell in neighbours(cell, rows, columns):
                if grid[neighbour_cell] == 'X':
                    continue
                if neighbour_cell in water or neighbour_cell in visited:
                    continue
                if grid[neighbour_cell] == 'D':
                    return str(minute) + "\n"
                visited.add(neighbour_cell)
                new_hedgehogs.add(neighbour_cell)
        hedgehogs = new_hedgehogs
    return "KAKTUS\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 3\nSD.\n") == "1\n"
assert oracle("1 3\nSXD\n") == "KAKTUS\n"
assert oracle("2 2\nS*\nD*\n") == "1\n"
assert oracle("3 3\nS..\n...\n..D\n") == "4\n"


def make_case(rows, columns, rng):
    grid = [['.'] * columns for _ in range(rows)]
    start = rng.randrange(rows * columns)
    den = rng.randrange(rows * columns - 1)
    if den >= start:
        den += 1
    for cell, symbol in [(start, 'S'), (den, 'D')]:
        row, column = divmod(cell, columns)
        grid[row][column] = symbol
    for row in range(rows):
        for column in range(columns):
            if grid[row][column] == '.':
                grid[row][column] = rng.choices(['.', '*', 'X'], weights=[70, 20, 10])[0]
    return str(rows) + " " + str(columns) + "\n" + "\n".join("".join(row) for row in grid) + "\n"


def write(name, text):
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", "3 3\nS..\n...\n..D\n")
    write("3_wide", "1 50\n" + "S" + "." * 48 + "D\n")
    write("4_random", make_case(12, 12, rng))
    write("5_io", make_case(50, 50, rng))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
