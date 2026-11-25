#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(grid):
    row_count = len(grid)
    column_count = len(grid[0])
    free_cells = [(row_index, column_index)
                  for row_index in range(row_count)
                  for column_index in range(column_count)
                  if grid[row_index][column_index] == '.']
    total = len(free_cells)
    if total == 0:
        return 0
    cell_index = {position: index for index, position in enumerate(free_cells)}
    neighbours = [[] for _ in free_cells]
    for row_index, column_index in free_cells:
        for row_step, column_step in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            neighbour = (row_index + row_step, column_index + column_step)
            if neighbour in cell_index:
                neighbours[cell_index[(row_index, column_index)]].append(cell_index[neighbour])
    full_mask = (1 << total) - 1
    route_count = 0
    for start in range(total):
        def walk(position, visited):
            nonlocal route_count
            if visited == full_mask:
                route_count += 1
                return
            for neighbour in neighbours[position]:
                if not (visited >> neighbour) & 1:
                    walk(neighbour, visited | (1 << neighbour))
        walk(start, 1 << start)
    return route_count % 1000000007


def parse(text):
    cases = []
    tokens = text.split()
    cursor = 0
    while cursor < len(tokens):
        row_count = int(tokens[cursor])
        column_count = int(tokens[cursor + 1])
        cursor += 2
        if row_count == 0 and column_count == 0:
            break
        grid = tokens[cursor:cursor + row_count]
        cursor += row_count
        cases.append(grid)
    return cases


def oracle_text(text):
    return "\n".join(str(oracle(grid)) for grid in parse(text)) + "\n"


SAMPLE = """3 3
...
.*.
...
3 7
...*...
.*.*.*.
.......
3 3
***
*.*
***
0 0
"""
SAMPLE_OUT = """16
8
1
"""
assert oracle_text(SAMPLE) == SAMPLE_OUT
assert oracle([".."]) == 2
assert oracle(["."]) == 1
assert oracle(["..", ".."]) == 8
assert oracle(["...", ".*.", "..."]) == 16


def encode(cases):
    lines = []
    for grid in cases:
        lines.append(f"{len(grid)} {len(grid[0])}")
        lines.extend(grid)
    lines.append("0 0")
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(input_text))


def build():
    write("2_edges", [["."], [".."], ["..", ".."], ["..", ".*"],
                      ["...", ".*.", "..."], ["***", "*.*", "***"]])
    wide = ["..*....", ".*.*.*.", "......."]
    write("3_wide", [wide])
    rng = random.Random(20261126)
    random_cases = []
    while len(random_cases) < 12:
        row_count = rng.randint(1, 4)
        column_count = rng.randint(1, 7)
        grid = [''.join('.' if rng.random() < 0.55 else '*'
                        for _ in range(column_count))
                for _ in range(row_count)]
        if 1 <= sum(row.count('.') for row in grid) <= 11:
            random_cases.append(grid)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(50):
        row_count = rng.randint(1, 3)
        column_count = rng.randint(1, 5)
        grid = [''.join('.' if rng.random() < 0.6 else '*'
                        for _ in range(column_count))
                for _ in range(row_count)]
        if sum(row.count('.') for row in grid) == 0:
            grid[0] = '.' + grid[0][1:]
        io_cases.append(grid)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [["...", ".*.", "..."],
                   ["...*...", ".*.*.*.", "......."],
                   ["***", "*.*", "***"]])
build()
