#!/usr/bin/env python3
import random
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    row_count, column_count = tokens[0], tokens[1]
    groups = defaultdict(list)
    position = 2
    for row in range(row_count):
        for column in range(column_count):
            groups[tokens[position]].append((row, column))
            position += 1
    present = [[0] * column_count for _ in range(row_count)]
    total = 0
    for value in sorted(groups, reverse=True):
        prefix = [[0] * (column_count + 1) for _ in range(row_count + 1)]
        for row in range(row_count):
            running = 0
            for column in range(column_count):
                running += present[row][column]
                prefix[row + 1][column + 1] = prefix[row][column + 1] + running
        for row, column in groups[value]:
            total += prefix[row + 1][column + 1]
        for row, column in groups[value]:
            present[row][column] = 1
    return str(total) + "\n"


def brute(text):
    tokens = [int(value) for value in text.split()]
    row_count, column_count = tokens[0], tokens[1]
    grid = []
    position = 2
    for row in range(row_count):
        grid.append(tokens[position:position + column_count])
        position += column_count
    total = 0
    for first_row in range(row_count):
        for first_column in range(column_count):
            for second_row in range(row_count):
                for second_column in range(column_count):
                    if first_row == second_row and first_column == second_column:
                        continue
                    if first_row > second_row or first_column > second_column:
                        continue
                    if grid[first_row][first_column] > grid[second_row][second_column]:
                        total += 1
    return str(total) + "\n"


SAMPLE = """4 4
3 4 2 5
1 7 11 16
8 9 6 12
10 13 15 14
"""
SAMPLE_OUT = "10\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n5\n") == "0\n"
assert oracle("2 2\n2 2\n2 2\n") == "0\n"
assert oracle("2 2\n4 3\n2 1\n") == "5\n"
assert oracle("3 3\n3 2 1\n3 2 1\n3 2 1\n") == "18\n"


def write(name, rows):
    text = f"{len(rows)} {len(rows[0])}\n"
    text += "".join(" ".join(str(value) for value in row) + "\n" for row in rows)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[5], [1], [8], [3], [9]])
    write("3_wide", [[(row * 17 + column * 7) % 20 + 1
                      for column in range(300)] for row in range(300)])
    rng = random.Random(20261126)
    write("4_random", [[rng.randint(1, 100000) for _ in range(30)]
                       for _ in range(24)])
    small = [[rng.randint(1, 12) for _ in range(6)] for _ in range(6)]
    assert brute(f"6 6\n" + "".join(" ".join(map(str, row)) + "\n"
                                   for row in small)) == oracle(
        f"6 6\n" + "".join(" ".join(map(str, row)) + "\n" for row in small))
    write("5_io", [[rng.randint(1, 10) for _ in range(300)]
                   for _ in range(300)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[3, 4, 2, 5], [1, 7, 11, 16], [8, 9, 6, 12],
                   [10, 13, 15, 14]])
build()
