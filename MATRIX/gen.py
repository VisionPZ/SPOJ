#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute(matrix):
    row_count = len(matrix)
    column_count = len(matrix[0])
    best = -10**9
    count = 0
    for top in range(row_count):
        for bottom in range(top, row_count):
            for left in range(column_count):
                for right in range(left, column_count):
                    border_sum = 0
                    for row in range(top, bottom + 1):
                        for column in range(left, right + 1):
                            if row in (top, bottom) or column in (left, right):
                                border_sum += 2 * matrix[row][column] - 1
                    if border_sum > best:
                        best, count = border_sum, 1
                    elif border_sum == best:
                        count += 1
    return best, count


def oracle(matrix):
    row_count = len(matrix)
    column_count = len(matrix[0])
    cell = [[2 * value - 1 for value in row] for row in matrix]
    row_prefix = [[0] * (column_count + 1) for _ in range(row_count)]
    for row in range(row_count):
        running = 0
        for column in range(column_count):
            running += cell[row][column]
            row_prefix[row][column + 1] = running
    col_prefix = [[0] * column_count for _ in range(row_count + 1)]
    for column in range(column_count):
        for row in range(row_count):
            col_prefix[row + 1][column] = col_prefix[row][column] + cell[row][column]
    best = -10**9
    count = 0

    def consider(value, ways):
        nonlocal best, count
        if value > best:
            best, count = value, ways
        elif value == best:
            count += ways

    for row in range(row_count):
        for column in range(column_count):
            consider(cell[row][column], 1)
    for column in range(column_count):
        min_prefix = 0
        min_count = 1
        for bottom in range(1, row_count):
            consider(col_prefix[bottom + 1][column] - min_prefix, min_count)
            here = col_prefix[bottom][column]
            if here < min_prefix:
                min_prefix, min_count = here, 1
            elif here == min_prefix:
                min_count += 1
    for left in range(column_count - 1):
        for right in range(left + 1, column_count):
            pair_prefix = 0
            best_left = -10**9
            left_count = 0
            for row in range(row_count):
                segment = row_prefix[row][right + 1] - row_prefix[row][left]
                pair_value = cell[row][left] + cell[row][right]
                consider(segment, 1)
                if row > 0:
                    consider(best_left + segment + pair_prefix, left_count)
                left_value = segment - pair_prefix - pair_value
                if left_value > best_left:
                    best_left, left_count = left_value, 1
                elif left_value == best_left:
                    left_count += 1
                pair_prefix += pair_value
    return best, count


def ones(rows, columns):
    return [[1] * columns for _ in range(rows)]


def zeros(rows, columns):
    return [[0] * columns for _ in range(rows)]


def checker(rows, columns):
    return [[(row + column) % 2 for column in range(columns)] for row in range(rows)]


def frame(rows, columns):
    grid = zeros(rows, columns)
    for column in range(columns):
        grid[0][column] = 1
        grid[rows - 1][column] = 1
    for row in range(rows):
        grid[row][0] = 1
        grid[row][columns - 1] = 1
    return grid


SAMPLE = [
    [1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1],
]

assert oracle(SAMPLE) == (18, 1)
assert brute(SAMPLE) == (18, 1)
assert oracle(zeros(3, 3)) == (-1, 9)
assert oracle(ones(20, 20)) == (76, 1)

seed_check = random.Random(4242)
for _ in range(60):
    check_columns = seed_check.randint(1, 5)
    check_rows = seed_check.randint(1, 5)
    small = [[seed_check.randint(0, 1) for _ in range(check_columns)]
             for _ in range(check_rows)]
    assert oracle(small) == brute(small)


def render(cases):
    text = str(len(cases)) + "\n"
    for matrix in cases:
        text += f"{len(matrix)} {len(matrix[0])}\n"
        for row in matrix:
            text += " ".join(str(value) for value in row) + "\n"
    return text


def write(name, cases):
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / f"{name}.txt").write_text(render(cases))
    answers = [oracle(matrix) for matrix in cases]
    (ROOT / "out" / f"{name}.out").write_text(
        "".join(f"{best} {count}\n" for best, count in answers))


write("1_sample", [SAMPLE])

write("2_edges", [
    [[1]], [[0]], ones(1, 5), zeros(5, 1),
    [[1], [0], [1], [0]], [[1, 0], [0, 1]],
    zeros(3, 3), ones(4, 4), frame(5, 6),
    ones(1, 200), ones(200, 1), zeros(1, 7),
])

write("3_wide", [
    ones(200, 200), zeros(200, 200), checker(200, 200),
    frame(200, 200), ones(200, 1), ones(1, 200),
])

rng = random.Random(20261125)
sizes = [(200, 200), (200, 200), (1, 200), (200, 1), (150, 180),
         (180, 150), (100, 200), (200, 100)]
random_cases = []
for rows, columns in sizes:
    density = rng.choice([0.2, 0.5, 0.8])
    random_cases.append([[1 if rng.random() < density else 0
                          for _ in range(columns)] for _ in range(rows)])
write("4_random", random_cases)

io_cases = []
for case_index in range(15):
    density = 0.3 + 0.4 * (case_index % 5) / 4
    io_cases.append([[1 if rng.random() < density else 0
                      for _ in range(200)] for _ in range(200)])
write("5_io", io_cases)
