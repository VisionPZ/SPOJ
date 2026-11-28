#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    lines = []
    for index in range(count):
        row = tokens[1 + 2 * index]
        column = tokens[2 + 2 * index]
        lines.append(str(knight_steps(row, column)))
    return "\n".join(lines) + "\n"


def knight_steps(row, column):
    wide = abs(row - 1)
    narrow = abs(column - 1)
    if wide < narrow:
        wide, narrow = narrow, wide
    if wide == 1 and narrow == 0:
        return 3
    if wide == 1 and narrow == 1:
        return 4
    if wide == 2 and narrow == 2:
        return 4
    steps = max((wide + 1) // 2, (wide + narrow + 2) // 3)
    if (steps + wide + narrow) % 2:
        steps += 1
    return steps


def brute_board(size):
    distances = [[-1] * size for _ in range(size)]
    distances[0][0] = 0
    queue = deque([(0, 0)])
    offsets = [(1, 2), (1, -2), (-1, 2), (-1, -2), (2, 1), (2, -1), (-2, 1), (-2, -1)]
    while queue:
        row, column = queue.popleft()
        for row_step, column_step in offsets:
            next_row = row + row_step
            next_column = column + column_step
            if 0 <= next_row < size and 0 <= next_column < size:
                if distances[next_row][next_column] < 0:
                    distances[next_row][next_column] = distances[row][column] + 1
                    queue.append((next_row, next_column))
    return distances


SAMPLE = """2
3 5
7 4
"""
SAMPLE_OUT = """2
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert knight_steps(1, 1) == 0
assert knight_steps(2, 1) == 3
assert knight_steps(3, 3) == 4
assert knight_steps(1000, 1000) == 666
small = brute_board(12)
for row in range(12):
    for column in range(12):
        assert small[row][column] == knight_steps(row + 1, column + 1)


def write(name, queries):
    text = f"{len(queries)}\n" + "\n".join(f"{row} {column}" for row, column in queries) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 2), (2, 1), (2, 2), (3, 3), (1000, 1000)])
    write("3_wide", [(1000, 999), (999, 1000), (1, 1000), (1000, 1), (500, 500)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 1000), rng.randint(1, 1000)) for _ in range(100)])
    write("5_io", [(rng.randint(1, 1000), rng.randint(1, 1000)) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 5), (7, 4)])
build()
