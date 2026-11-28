#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = [(1, 0), (0, 1), (-1, 0), (0, -1)]


def arm_length(arm_index, size):
    if arm_index <= 2:
        return size - 1
    return size - 3 - 2 * ((arm_index - 3) // 2)


def build_grid(size):
    grid = [['.'] * size for _ in range(size)]
    row, col = 0, 0
    grid[row][col] = '*'
    for arm_index in range(size):
        length = arm_length(arm_index, size)
        row_step, col_step = DIRECTIONS[arm_index % 4]
        for _ in range(length):
            row += row_step
            col += col_step
            grid[row][col] = '*'
    return grid


def oracle_cell(size, row, col):
    if row == 0 and col == 0:
        return '*'
    walk_row, walk_col = 0, 0
    for arm_index in range(size):
        length = arm_length(arm_index, size)
        row_step, col_step = DIRECTIONS[arm_index % 4]
        if row_step == 1:
            if col == walk_col and walk_row + 1 <= row <= walk_row + length:
                return '*'
        elif row_step == -1:
            if col == walk_col and walk_row - length <= row <= walk_row - 1:
                return '*'
        elif col_step == 1:
            if row == walk_row and walk_col + 1 <= col <= walk_col + length:
                return '*'
        else:
            if row == walk_row and walk_col - length <= col <= walk_col - 1:
                return '*'
        walk_row += row_step * length
        walk_col += col_step * length
    return '.'


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        size = int(tokens[cursor]); cursor += 1
        one_based_row = int(tokens[cursor]); cursor += 1
        one_based_col = int(tokens[cursor]); cursor += 1
        answers.append(oracle_cell(size, one_based_row - 1, one_based_col - 1))
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = "3\n3 1 1\n4 3 2\n5 2 3\n"
STATEMENT_SAMPLE_LITERAL = "*.*\n"
SAMPLE_OUTPUT = "*\n.\n*\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle(SAMPLE_INPUT).replace("\n", "") + "\n" == STATEMENT_SAMPLE_LITERAL
assert oracle("1\n9 1 1\n") == "*\n"
assert oracle("1\n9 1 2\n") == ".\n"
assert oracle("1\n9 9 9\n") == "*\n"
assert oracle("1\n6 3 4\n") == ".\n"
assert oracle("1\n6 4 4\n") == "*\n"

for check_size in range(3, 40):
    check_grid = build_grid(check_size)
    for check_row in range(check_size):
        for check_col in range(check_size):
            assert check_grid[check_row][check_col] == oracle_cell(check_size, check_row, check_col)
print("spiral oracle cross-check done")


def write(name, queries):
    input_text = str(len(queries)) + "\n"
    for size, one_row, one_col in queries:
        input_text += "%d %d %d\n" % (size, one_row, one_col)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [(3, 1, 1), (4, 3, 2), (5, 2, 3)])
edges = []
for edge_size in range(3, 16):
    for one_row in range(1, edge_size + 1):
        for one_col in range(1, edge_size + 1):
            edges.append((edge_size, one_row, one_col))
edges.extend([(10000, 1, 1), (10000, 10000, 10000), (10000, 1, 2),
              (10000, 10000, 9999), (10000, 5000, 5000), (9999, 1, 2)])
write("2_edges", edges)
random.seed(2026)
write("3_wide", [(random.randint(3, 10000), random.randint(1, 10000),
                  random.randint(1, 10000)) for _ in range(200)])
write("4_random", [(random.randint(3, 500), random.randint(1, 500),
                    random.randint(1, 500)) for _ in range(300)])
write("5_io", [(random.randint(3, 10000), random.randint(1, 10000),
                random.randint(1, 10000)) for _ in range(1000)])
