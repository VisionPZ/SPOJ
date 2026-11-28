#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    cases = []
    for _ in range(count):
        row_count = int(tokens[cursor]); cursor += 1
        column_count = int(tokens[cursor]); cursor += 1
        grid = [tokens[cursor + row_index] for row_index in range(row_count)]
        cursor += row_count
        cases.append((row_count, column_count, grid))
    return cases


def bfs(case):
    row_count, column_count, grid = case
    infinity = 10 ** 9
    distance = [[infinity] * column_count for _ in range(row_count)]
    queue = deque()
    for row_index in range(row_count):
        for column_index in range(column_count):
            if grid[row_index][column_index] == '1':
                distance[row_index][column_index] = 0
                queue.append((row_index, column_index))
    while queue:
        row_index, column_index = queue.popleft()
        for row_step, column_step in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            next_row = row_index + row_step
            next_column = column_index + column_step
            if 0 <= next_row < row_count and 0 <= next_column < column_count:
                if distance[next_row][next_column] == infinity:
                    distance[next_row][next_column] = distance[row_index][column_index] + 1
                    queue.append((next_row, next_column))
    return distance


def brute(case):
    row_count, column_count, grid = case
    whites = [(row_index, column_index)
              for row_index in range(row_count)
              for column_index in range(column_count)
              if grid[row_index][column_index] == '1']
    return [[min(abs(row_index - white_row) + abs(column_index - white_column)
                 for white_row, white_column in whites)
             for column_index in range(column_count)]
            for row_index in range(row_count)]


def oracle(text):
    lines = []
    for case in parse(text):
        for row in bfs(case):
            lines.append(" ".join(str(value) for value in row))
    return "\n".join(lines) + "\n"


def render(cases):
    blocks = []
    for row_count, column_count, grid in cases:
        blocks.append(f"{row_count} {column_count}\n" + "\n".join(grid) + "\n")
    return str(len(cases)) + "\n" + "".join(blocks)


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_case(row_count, column_count, white_count, rng):
    cells = [(i, j) for i in range(row_count) for j in range(column_count)]
    chosen = rng.sample(cells, white_count)
    grid = [["0"] * column_count for _ in range(row_count)]
    for row_index, column_index in chosen:
        grid[row_index][column_index] = "1"
    return (row_count, column_count, ["".join(row) for row in grid])


SAMPLE_CASES = [(3, 4, ["0001", "0011", "0110"])]
SAMPLE_INPUT = render(SAMPLE_CASES)
SAMPLE_OUTPUT = "3 2 1 0\n2 1 0 0\n1 0 0 1\n"

assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n2 2\n10\n00\n") == "0 1\n1 2\n"
assert bfs((2, 2, ["10", "00"])) == brute((2, 2, ["10", "00"]))
assert bfs((3, 4, ["0001", "0011", "0110"])) == brute((3, 4, ["0001", "0011", "0110"]))

rng_check = random.Random(7)
for _ in range(40):
    small = random_case(rng_check.randint(1, 6), rng_check.randint(1, 6), 1, rng_check)
    assert bfs(small) == brute(small)


def build():
    edges = [
        (1, 1, ["1"]),
        (1, 7, ["0001000"]),
        (7, 1, ["0", "0", "1", "0", "0", "0", "0"]),
        (3, 3, ["000", "010", "000"]),
        (2, 2, ["11", "11"]),
        (4, 4, ["0000", "0000", "0000", "1000"]),
    ]
    write("2_edges", edges)

    wide = [
        (182, 182, make_corner(182, 182, 0, 0)),
        (182, 182, make_corner(182, 182, 181, 181)),
        (182, 182, make_corner(182, 182, 91, 91)),
        (182, 182, ["1" * 182 for _ in range(182)]),
    ]
    write("3_wide", wide)

    rng = random.Random(2026)
    random_cases = []
    for _ in range(20):
        row_count = rng.randint(1, 182)
        column_count = rng.randint(1, 182)
        white_count = rng.randint(1, max(1, (row_count * column_count) // 5))
        random_cases.append(random_case(row_count, column_count, white_count, rng))
    write("4_random", random_cases)

    io_cases = []
    for _ in range(60):
        io_cases.append((182, 182, make_corner(182, 182, 0, 0)))
    write("5_io", io_cases)


def make_corner(row_count, column_count, white_row, white_column):
    grid = [["0"] * column_count for _ in range(row_count)]
    grid[white_row][white_column] = "1"
    return ["".join(row) for row in grid]


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
