#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle(text):
    tokens = [int(value) for value in text.split()]
    field_size = tokens[0]
    window_size = tokens[1]
    cursor = 2
    grid = []
    for _ in range(field_size):
        initial_value = tokens[cursor]
        multiplier = tokens[cursor + 1]
        addend = tokens[cursor + 2]
        modulus = tokens[cursor + 3]
        cursor += 4
        row = []
        current = initial_value
        for _ in range(field_size):
            row.append(current)
            current = (current * multiplier + addend) % modulus
        grid.append(row)
    total = 0
    for top in range(field_size - window_size + 1):
        for left in range(field_size - window_size + 1):
            smallest = min(grid[row][column]
                           for row in range(top, top + window_size)
                           for column in range(left, left + window_size))
            total = (total + smallest) % MODULUS
    return str(total) + "\n"


SAMPLE = """4 2
8 2 9 9
5 7 9 3
9 7 7 5
7 4 7 3
"""
SAMPLE_OUT = """6
"""
SECOND = """10 8
78 51 99 77
27 95 37 80
76 5 93 32
92 48 56 64
93 17 18 28
70 30 15 73
60 69 36 56
12 11 63 57
18 81 55 60
59 92 68 81
"""
SECOND_OUT = """18
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == SECOND_OUT
assert oracle("1 1\n0 0 0 1\n") == "0\n"
assert oracle("2 2\n1 1 0 5\n1 1 0 5\n") == "1\n"
assert oracle("2 1\n5 0 0 6\n5 0 0 6\n") == "10\n"


def write(name, field_size, window_size, rows):
    text = f"{field_size} {window_size}\n" + "".join(
        " ".join(str(value) for value in row) + "\n" for row in rows)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 3, 3, [[7, 0, 0, 11], [0, 0, 0, 1], [3, 2, 5, 9]])
    write("3_wide", 16, 4, [[10**18, 10**18, 13, 10**18] for _ in range(16)])
    rng = random.Random(20261126)
    write("4_random", 14, 3, [[rng.randint(0, 10**18), rng.randint(0, 10**18),
                              rng.randint(0, 10**18), rng.randint(1, 10**18)]
                             for _ in range(14)])
    write("5_io", 12, 1, [[rng.randint(0, 1000), 3, 7, 1009] for _ in range(12)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 4, 2, [[8, 2, 9, 9], [5, 7, 9, 3], [9, 7, 7, 5], [7, 4, 7, 3]])
build()
