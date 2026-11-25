#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def values(rows):
    return [[0 if cell == 'P' else int(cell) for cell in row] for row in rows]


def enumerate_paths(rows, start_column):
    row_count = len(rows)
    column_count = len(rows[0])
    paths = []

    def walk(row, column, probability, visited):
        visited = set(visited)
        visited.add((row, column))
        if row == row_count - 1:
            paths.append((probability, frozenset(visited)))
            return
        if rows[row + 1][column] != 'P':
            walk(row + 1, column, probability, visited)
            return
        for direction in (-1, 1):
            step = column + direction
            extended = set(visited)
            while 0 <= step < column_count and rows[row + 1][step] == 'P':
                extended.add((row, step))
                step += direction
            extended.add((row, step))
            walk(row + 1, step, probability * Fraction(1, 2), frozenset(extended))

    walk(0, start_column, Fraction(1), frozenset())
    return paths


def oracle_case(rows):
    grid = values(rows)
    row_count = len(rows)
    column_count = len(rows[0])
    paths = [enumerate_paths(rows, column) for column in range(column_count)]
    best = Fraction(0)
    for first in range(column_count):
        for second in range(column_count):
            expected = Fraction(0)
            for first_probability, first_cells in paths[first]:
                for second_probability, second_cells in paths[second]:
                    score = sum(grid[row][column] for row, column in first_cells | second_cells)
                    expected += first_probability * second_probability * score
            if expected > best:
                best = expected
    scaled = int(best * 10000 + Fraction(1, 2))
    return f"{scaled // 10000}.{scaled % 10000:04d}"


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
        rows = tokens[cursor:cursor + row_count]
        cursor += row_count
        answers.append(oracle_case(rows))
    return "\n".join(answers) + "\n"


SAMPLE = """4
5 5
53214
53214
53214
54214
53214
5 5
00000
0P0P0
00000
01P20
00000
5 5
09090
0P0P0
00000
01P20
00000
6 6
112214
211243
30PPP2
423378
1P9753
220102
"""
SAMPLE_OUT = """45.0000
2.2500
19.3125
35.5000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(["000", "000", "000"]) == "0.0000"
assert oracle_case(["123", "456", "789"]) == "33.0000"
assert oracle_case(["111", "1P1", "111"]) == "6.0000"
assert oracle("1\n3 3\n999\n999\n999\n") == "54.0000\n"


def random_grid(row_count, column_count, rng, platform_chance):
    platforms = set()
    for row in range(1, row_count - 1):
        for column in range(1, column_count - 1):
            if rng.random() < platform_chance:
                platforms.add((row, column))
    changed = True
    while changed:
        changed = False
        for row, column in sorted(platforms):
            for neighbor_row in (row - 1, row + 1):
                for neighbor_column in (column - 1, column + 1):
                    if (neighbor_row, neighbor_column) in platforms:
                        platforms.remove((row, column))
                        changed = True
                        break
                if changed:
                    break
            if changed:
                break
    rows = []
    for row in range(row_count):
        cells = []
        for column in range(column_count):
            if (row, column) in platforms:
                cells.append('P')
            else:
                cells.append(str(rng.randint(0, 9)))
        rows.append("".join(cells))
    return rows


def write(name, cases):
    text = str(len(cases))
    for row_count, column_count, rows in cases:
        text += f"\n{row_count} {column_count}"
        for row in rows:
            text += "\n" + row
    text += "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = [
        (3, 3, ["000", "000", "000"]),
        (3, 3, ["123", "1P3", "789"]),
        (3, 4, ["1111", "1PP1", "2222"]),
    ]
    write("2_edges", edges)
    rng = random.Random(20261126)
    write("3_wide", [(7, 7, random_grid(7, 7, rng, 0.35)) for _ in range(3)])
    random_cases = []
    for _ in range(12):
        random_rows = rng.randint(3, 7)
        random_columns = rng.randint(3, 7)
        random_cases.append((random_rows, random_columns,
                             random_grid(random_rows, random_columns, rng, 0.25)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(18000):
        rows = ["".join(str(rng.randint(0, 9)) for _ in range(3)) for _ in range(3)]
        io_cases.append((3, 3, rows))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_cases = [
    (5, 5, ["53214", "53214", "53214", "54214", "53214"]),
    (5, 5, ["00000", "0P0P0", "00000", "01P20", "00000"]),
    (5, 5, ["09090", "0P0P0", "00000", "01P20", "00000"]),
    (6, 6, ["112214", "211243", "30PPP2", "423378", "1P9753", "220102"]),
]
write("1_sample", sample_cases)
build()
