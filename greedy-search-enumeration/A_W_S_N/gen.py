#!/usr/bin/env python3
import random
from pathlib import Path
from collections import deque

ROOT = Path(__file__).resolve().parent


def oracle_case(grid):
    rows = len(grid)
    columns = len(grid[0])
    start = None
    destination = None
    chocolates = {}
    for row in range(rows):
        for column in range(columns):
            cell = grid[row][column]
            if cell == 'T':
                start = (row, column)
            elif cell == 'W':
                destination = (row, column)
            elif cell == 'C':
                chocolates[(row, column)] = len(chocolates)
    full_mask = (1 << len(chocolates)) - 1
    initial = (start[0], start[1], 0)
    queue = deque([initial])
    distance = {initial: 0}
    while queue:
        row, column, mask = queue.popleft()
        if (row, column) == destination and mask == full_mask:
            return distance[(row, column, mask)]
        for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            next_row = row + delta_row
            next_column = column + delta_column
            if not (0 <= next_row < rows and 0 <= next_column < columns):
                continue
            if grid[next_row][next_column] == '#':
                continue
            next_mask = mask
            if (next_row, next_column) in chocolates:
                next_mask |= 1 << chocolates[(next_row, next_column)]
            state = (next_row, next_column, next_mask)
            if state not in distance:
                distance[state] = distance[(row, column, mask)] + 1
                queue.append(state)
    return None


def oracle(text):
    tokens = text.split()
    cursor = 0
    test_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(test_count):
        row_count = int(tokens[cursor])
        column_count = int(tokens[cursor + 1])
        cursor += 2
        grid = tokens[cursor:cursor + row_count]
        cursor += row_count
        result = oracle_case(grid)
        answers.append("Mission Failed!" if result is None else str(result))
    return "\n".join(answers) + "\n"


SAMPLE = """8
3 3
T..
...
..W
3 6
######
#T..W#
######
3 6
######
#T#.W#
######
3 6
##C###
#T..W#
######
3 6
C#C###
.T..W#
######
5 10
##########
#T.#.C#..#
#..#..#..#
#..W..#..#
##########
5 10
##########
#T.#.C#.C#
#..#..#..#
#..W..#..#
##########
5 10
##########
#C.#.C#.C#
#..#..#..#
#..T..W..#
##########
"""
SAMPLE_OUT = """4
3
Mission Failed!
5
9
12
Mission Failed!
23
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 2\nT.\n.W\n") == "2\n"
assert oracle("1\n2 2\nT#\n#W\n") == "Mission Failed!\n"
assert oracle("1\n3 3\nT.C\n...\n..W\n") == "4\n"
assert oracle("1\n1 3\nTCW\n") == "2\n"


def write(name, cases):
    parts = [str(len(cases))]
    for grid in cases:
        parts.append(f"{len(grid)} {len(grid[0])}")
        parts.extend(grid)
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [["T.", ".W"], ["T#", "#W"], ["TCW"], ["T.C", "...", "..W"]])
    wide_open = ["T" + "." * 8 + "W"] + ["." * 10 for _ in range(8)]
    wide_open[4] = "....C....."
    write("3_wide", [wide_open, ["T..C..W"]])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        rows = rng.randint(2, 8)
        columns = rng.randint(2, 8)
        grid = []
        for row in range(rows):
            line = []
            for column in range(columns):
                if rng.random() < 0.25:
                    line.append('#')
                else:
                    line.append('.')
            grid.append(line)
        open_cells = [(row, column) for row in range(rows) for column in range(columns)
                      if grid[row][column] == '.']
        rng.shuffle(open_cells)
        if len(open_cells) < 4:
            continue
        grid[open_cells[0][0]][open_cells[0][1]] = 'T'
        grid[open_cells[1][0]][open_cells[1][1]] = 'W'
        grid[open_cells[2][0]][open_cells[2][1]] = 'C'
        if rng.random() < 0.5 and len(open_cells) > 3:
            grid[open_cells[3][0]][open_cells[3][1]] = 'C'
        random_cases.append(["".join(line) for line in grid])
    write("4_random", random_cases)
    failed_grid = ["T####", "##.##", "####W"]
    write("5_io", [failed_grid for _ in range(30)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [["T..", "...", "..W"], ["######", "#T..W#", "######"],
                   ["######", "#T#.W#", "######"], ["##C###", "#T..W#", "######"],
                   ["C#C###", ".T..W#", "######"],
                   ["##########", "#T.#.C#..#", "#..#..#..#", "#..W..#..#", "##########"],
                   ["##########", "#T.#.C#.C#", "#..#..#..#", "#..W..#..#", "##########"],
                   ["##########", "#C.#.C#.C#", "#..#..#..#", "#..T..W..#", "##########"]])
build()
