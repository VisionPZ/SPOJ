#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for PG1118.

The statement gives the placing rule and three example squares.
The oracle uses the equivalent rule that a sideways step follows every multiple of n.
The solution instead tests the target cell for occupancy on every step.
Both rules are checked against each other for all small odd orders.
"""
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n"
SAMPLE_OUTPUT = "15\n2 7 6\n9 5 1\n4 3 8\n"
SAMPLE_FIVE_OUTPUT = (
    "65\n"
    "9 3 22 16 15\n"
    "2 21 20 14 8\n"
    "25 19 13 7 1\n"
    "18 12 6 5 24\n"
    "11 10 4 23 17\n"
)


def step_count_square(order):
    grid = [[0] * order for _ in range(order)]
    row, col = order // 2, order - 1
    for value in range(1, order * order + 1):
        grid[row][col] = value
        if value % order == 0:
            col = (col - 1) % order
        else:
            row = (row - 1) % order
            col = (col + 1) % order
    return grid


def occupancy_square(order):
    grid = [[0] * order for _ in range(order)]
    row, col = order // 2, order - 1
    for value in range(1, order * order + 1):
        grid[row][col] = value
        next_row, next_col = (row - 1) % order, (col + 1) % order
        if grid[next_row][next_col] != 0:
            col = (col - 1) % order
        else:
            row, col = next_row, next_col
    return grid


def oracle(text):
    order = int(text.split()[0])
    grid = step_count_square(order)
    magic_constant = order * (order * order + 1) // 2
    lines = [str(magic_constant)]
    lines.extend(" ".join(str(value) for value in row) for row in grid)
    return "\n".join(lines) + "\n"


def write(name, order):
    input_text = str(order) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("5\n") == SAMPLE_FIVE_OUTPUT
assert SAMPLE_OUTPUT.splitlines()[0] == "15"
assert step_count_square(7)[3][3] == 25
for odd_order in range(1, 32, 2):
    assert step_count_square(odd_order) == occupancy_square(odd_order)


def trace_example():
    order = 3
    row, col = order // 2, order - 1
    for value in range(1, 10):
        print("place %d at row %d col %d" % (value, row, col))
        if value % order == 0:
            col = (col - 1) % order
            print("  next step sideways to col %d" % col)
        else:
            row, col = (row - 1) % order, (col + 1) % order


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", 3)
    write("2_edges", 1)
    write("3_wide", 101)
    random.seed(2026)
    write("4_random", random.choice([5, 7, 9, 11, 13, 15, 21, 31, 51]))
    write("5_io", 501)
