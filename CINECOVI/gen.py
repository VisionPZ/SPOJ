#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    row_count = tokens[0]
    column_count = tokens[1]
    groups = tokens[2:]
    grid = [["0"] * column_count for _ in range(row_count)]
    failed = []
    current_row = 0
    for group_index, size in enumerate(groups):
        placed = False
        for row in range(current_row, row_count, 2):
            for start in range(column_count - size + 1):
                block = grid[row][start:start + size]
                if "1" in block:
                    continue
                if start > 0 and grid[row][start - 1] == "1":
                    continue
                if start + size < column_count and grid[row][start + size] == "1":
                    continue
                for column in range(start, start + size):
                    grid[row][column] = "1"
                current_row = row
                placed = True
                break
            if placed:
                break
        if not placed:
            failed = groups[group_index:]
            break
    result = "Seats:" + "".join("".join(row) for row in reversed(grid))
    if failed:
        result += "Failed to seat:" + "".join(str(value) for value in failed)
    return result + "\n"


SAMPLE = """5 20 7 9 8 7 6 5 4 3 2 1 9 2 11 4 8
"""
SAMPLE_OUT = """Seats:1111110111110111100000000000000000000000111111110111111100000000000000000000000011111110111111111000Failed to seat:321921148
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 10 5 4 3 2 1\n") == (
    "Seats:111011010000000000001111101111\n")
assert oracle("3 10 5 4 3 2 1 1 2 3 4 5\n") == (
    "Seats:111011010100000000001111101111Failed to seat:2345\n")
assert oracle("1 1 1 1\n") == "Seats:1Failed to seat:1\n"
assert 3 * 10 == 30


def write(name, row_count, column_count, groups):
    text = f"{row_count} {column_count} " + " ".join(str(v) for v in groups) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, [1, 1])
    write("3_wide", 3, 50, [10, 12, 8, 15, 6, 4, 20, 3])
    rng = random.Random(20261126)
    write("4_random", 6, 30, [rng.randint(1, 12) for _ in range(25)])
    write("5_io", 200, 800, [rng.randint(1, 25) for _ in range(120)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, 20, [7, 9, 8, 7, 6, 5, 4, 3, 2, 1, 9, 2, 11, 4, 8])
build()
