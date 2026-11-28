#!/usr/bin/env python3
from collections import deque
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(rows, cols, balls):
    start = frozenset(balls)
    if len(start) <= 1:
        return "Yes\n"
    queue = deque([start])
    seen = {start}
    while queue:
        state = queue.popleft()
        grid = set(state)
        neighbours = set()
        for row in range(rows):
            line = sorted(column for ball_row, column in state if ball_row == row)
            for source_index, source in enumerate(line):
                for step in (-1, 1):
                    ray = ([column for column in line if column > source]
                           if step == 1 else
                           [column for column in line if column < source][::-1])
                    if not ray or abs(ray[0] - source) < 2:
                        continue
                    candidate = set(state)
                    candidate.remove((row, source))
                    for column in ray:
                        candidate.remove((row, column))
                        candidate.add((row, column - step))
                    neighbours.add(frozenset(candidate))
        for column in range(cols):
            line = sorted(row for row, ball_column in state if ball_column == column)
            for source_index, source in enumerate(line):
                for step in (-1, 1):
                    ray = ([row for row in line if row > source]
                           if step == 1 else
                           [row for row in line if row < source][::-1])
                    if not ray or abs(ray[0] - source) < 2:
                        continue
                    candidate = set(state)
                    candidate.remove((source, column))
                    for row in ray:
                        candidate.remove((row, column))
                        candidate.add((row - step, column))
                    neighbours.add(frozenset(candidate))
        for candidate in neighbours:
            if len(candidate) <= 1:
                return "Yes\n"
            if candidate not in seen:
                seen.add(candidate)
                queue.append(candidate)
    return "No\n"


SAMPLE_CASES = [
    (5, 5, [(2, 2), (4, 1), (4, 4)]),
    (5, 4, [(1, 0), (2, 0), (4, 0)]),
    (3, 4, [(0, 0), (0, 1), (2, 1)]),
    (1, 1, [(0, 0)]),
]
SAMPLE_OUT = "Yes\nYes\nNo\nYes\n"


def oracle_text(cases):
    return "".join(oracle(rows, cols, balls) for rows, cols, balls in cases)


assert oracle_text(SAMPLE_CASES) == SAMPLE_OUT
assert oracle(1, 5, [(0, 0)]) == "Yes\n"
assert oracle(1, 5, [(0, 1), (0, 2)]) == "No\n"
assert oracle(1, 5, [(0, 1), (0, 4)]) == "Yes\n"
assert oracle(3, 3, [(0, 0), (2, 2)]) == "No\n"


def write(name, cases):
    chunks = [str(len(cases))]
    for rows, cols, balls in cases:
        chunks.append(f"{rows} {cols}")
        grid = [["." for _ in range(cols)] for _ in range(rows)]
        for row, column in balls:
            grid[row][column] = "B"
        chunks.extend("".join(line) for line in grid)
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


def build():
    write("2_edges", [(1, 1, [(0, 0)]), (1, 4, [(0, 0), (0, 1)]),
                      (1, 4, [(0, 0), (0, 3)]), (4, 1, [(0, 0), (2, 0)]),
                      (4, 4, [(0, 0), (3, 3)])])
    write("3_wide", [(8, 8, [(0, 0), (0, 4), (4, 0), (4, 4), (7, 7)]),
                     (10, 10, [(row, row) for row in range(0, 10, 3)]),
                     (6, 6, [(0, 0), (2, 2), (4, 4), (5, 5), (3, 1)])])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(60):
        rows = rng.randint(1, 7)
        cols = rng.randint(1, 7)
        positions = rng.sample(range(rows * cols), rng.randint(1, min(6, rows * cols)))
        balls = [(position // cols, position % cols) for position in positions]
        random_cases.append((rows, cols, balls))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(300):
        rows = rng.randint(1, 3)
        cols = rng.randint(1, 3)
        positions = rng.sample(range(rows * cols), rng.randint(1, min(2, rows * cols)))
        io_cases.append((rows, cols, [(position // cols, position % cols)
                                      for position in positions]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
SAMPLE = """4
5 5
.....
.....
..B..
.....
.B..B
5 4
....
B...
B...
....
B...
3 4
BB..
....
.B..
1 1
B
"""
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
