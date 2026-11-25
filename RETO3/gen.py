#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n4 0 2\n3 5 7\n8 1 6\n"
SAMPLE_OUTPUT = "9\n"
SECOND_INPUT = "4\n1 1 1 1\n1 1 0 1\n1 1 1 1\n1 1 1 1\n"
SECOND_OUTPUT = "1\n"
THIRD_INPUT = "4\n1 1 1 1\n1 1 0 1\n1 1 2 1\n1 1 1 1\n"
THIRD_OUTPUT = "-1\n"


def parse_grid(text):
    tokens = text.split()
    order = int(tokens[0])
    values = [int(token) for token in tokens[1:]]
    grid = [values[row * order:(row + 1) * order] for row in range(order)]
    return grid


def oracle(text):
    grid = parse_grid(text)
    order = len(grid)
    if order == 1:
        return "1\n"
    empty_row = next(row for row in range(order) if 0 in grid[row])
    empty_column = grid[empty_row].index(0)
    reference_column = 0 if empty_column != 0 else 1
    target = sum(grid[row][reference_column] for row in range(order))
    candidate = target - sum(grid[empty_row])
    if candidate < 1:
        return "-1\n"
    filled = [row[:] for row in grid]
    filled[empty_row][empty_column] = candidate
    line_sums = []
    line_sums.extend(sum(row) for row in filled)
    line_sums.extend(sum(filled[row][column] for row in range(order)) for column in range(order))
    line_sums.append(sum(filled[index][index] for index in range(order)))
    line_sums.append(sum(filled[index][order - 1 - index] for index in range(order)))
    if len(set(line_sums)) != 1:
        return "-1\n"
    return str(candidate) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle(SECOND_INPUT) == SECOND_OUTPUT
assert oracle(THIRD_INPUT) == THIRD_OUTPUT
assert oracle("1\n0\n") == "1\n"
assert oracle("2\n0 2\n2 2\n") == "2\n"
assert oracle("3\n1 1 1\n1 0 1\n1 1 1\n") == "1\n"
assert oracle("3\n1000000000 1000000000 1000000000\n1000000000 0 1000000000\n1000000000 1000000000 1000000000\n") == "1000000000\n"


def write(name, grid):
    input_text = str(len(grid)) + "\n" + "\n".join(
        " ".join(str(cell) for cell in row) for row in grid) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def constant_grid(order, cell_value, empty_row, empty_column):
    grid = [[cell_value] * order for _ in range(order)]
    grid[empty_row][empty_column] = 0
    return grid


def trace():
    grid = parse_grid(SAMPLE_INPUT)
    order = len(grid)
    empty_row = next(row for row in range(order) if 0 in grid[row])
    empty_column = grid[empty_row].index(0)
    reference_column = 0 if empty_column != 0 else 1
    target = sum(grid[row][reference_column] for row in range(order))
    print(f"grid order {order}, empty cell row {empty_row + 1}, column {empty_column + 1}")
    print(f"reference column {reference_column + 1} total {target}")
    print(f"empty row total {sum(grid[empty_row])}, candidate {target - sum(grid[empty_row])}")
    filled = [row[:] for row in grid]
    filled[empty_row][empty_column] = target - sum(grid[empty_row])
    print("filled rows", [sum(row) for row in filled])
    print("filled columns", [sum(filled[row][column] for row in range(order)) for column in range(order)])
    print("filled diagonals", [sum(filled[index][index] for index in range(order)),
                               sum(filled[index][order - 1 - index] for index in range(order))])


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", parse_grid(SAMPLE_INPUT))
        write("2_edges", [[0]])
        write("3_wide", constant_grid(500, 10**9, 250, 250))
        random.seed(2026)
        random_grid = [[random.randint(1, 10**9) for _ in range(250)] for _ in range(250)]
        random_grid[123][77] = 0
        write("4_random", random_grid)
        write("5_io", constant_grid(500, 10**9, 0, 0))
