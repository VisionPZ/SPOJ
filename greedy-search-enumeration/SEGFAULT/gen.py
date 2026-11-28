#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = {'R': (0, 1), 'L': (0, -1), 'D': (1, 0), 'U': (-1, 0)}


def oracle(text):
    lines = text.splitlines()
    rows, columns = map(int, lines[0].split())
    grid = [list(lines[index + 1]) for index in range(rows)]
    program_count = int(lines[rows + 1])
    programs = []
    for index in range(program_count):
        x, y, direction = lines[rows + 2 + index].split()
        programs.append((int(x) - 1, int(y) - 1, direction))

    owner = [['.' for _ in range(columns)] for _ in range(rows)]
    for row in range(rows):
        for column in range(columns):
            if grid[row][column] == '#':
                owner[row][column] = 'X'
            elif grid[row][column] == 'S':
                owner[row][column] = 'P'

    active = []
    for row, column, direction in programs:
        if grid[row][column] != '#':
            active.append([row, column, direction, False])

    for _ in range(2 * (rows + columns) + 5):
        petar_targets = set()
        for row in range(rows):
            for column in range(columns):
                if owner[row][column] == 'P':
                    for delta_row, delta_column in DIRECTIONS.values():
                        next_row = row + delta_row
                        next_column = column + delta_column
                        if (0 <= next_row < rows and 0 <= next_column < columns and
                                owner[next_row][next_column] == '.'):
                            petar_targets.add((next_row, next_column))

        nikolaj_targets = {}
        still_active = []
        for program in active:
            row, column, direction, started = program
            if not started:
                if owner[row][column] == '.':
                    nikolaj_targets[(row, column)] = program
                    still_active.append([row, column, direction, True])
                continue
            delta_row, delta_column = DIRECTIONS[direction]
            next_row = row + delta_row
            next_column = column + delta_column
            if not (0 <= next_row < rows and 0 <= next_column < columns):
                continue
            if owner[next_row][next_column] in ('P', 'X'):
                continue
            nikolaj_targets[(next_row, next_column)] = program
            still_active.append([next_row, next_column, direction, True])

        new_petar = petar_targets - set(nikolaj_targets)
        for row, column in new_petar:
            owner[row][column] = 'P'
        for row, column in nikolaj_targets:
            owner[row][column] = 'N'
        active = still_active
        if not active and not new_petar:
            break

    return str(sum(1 for row in range(rows) for column in range(columns)
                   if owner[row][column] == 'P')) + "\n"


SAMPLE = """6 5
#.S.#
.....
.....
...##
##...
...##
2
2 1 R
3 5 L
"""
SAMPLE_OUT = """18
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\nS\n0\n") == "1\n"
assert oracle("1 3\nS#.\n0\n") == "1\n"
assert oracle("2 2\nS.\n..\n0\n") == "4\n"
assert oracle("2 2\nS.\n..\n1\n2 1 R\n") == "2\n"


def write_case(name, grid, programs):
    rows = len(grid)
    columns = len(grid[0])
    lines = [f"{rows} {columns}"] + [''.join(row) for row in grid]
    lines.append(str(len(programs)))
    for row, column, direction in programs:
        lines.append(f"{row + 1} {column + 1} {direction}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [['S']], [])
    wide_grid = [list('.' * 30) for _ in range(20)]
    wide_grid[10][0] = 'S'
    write_case("3_wide", wide_grid,
               [(0, 29, 'L'), (19, 0, 'R'), (10, 0, 'R'), (5, 29, 'U')])
    rng = random.Random(20261126)
    grid = [[rng.choice('.#.') for _ in range(8)] for _ in range(8)]
    grid[3][3] = 'S'
    programs = []
    for _ in range(8):
        while True:
            row, column = rng.randrange(8), rng.randrange(8)
            if grid[row][column] != '#':
                break
        programs.append((row, column, rng.choice('RLUD')))
    write_case("4_random", grid, programs)
    big_grid = [list('.' * 40) for _ in range(40)]
    big_grid[20][20] = 'S'
    big_programs = [(row, 0, 'R') for row in range(0, 40, 5)]
    write_case("5_io", big_grid, big_programs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
