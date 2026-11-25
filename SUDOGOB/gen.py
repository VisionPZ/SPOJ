#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW_SAMPLE = '33 0 6 0 0 2 5 0 00 0 0 0 3 8 0 0 07 0 8 0 1 6 0 9 00 0 7 0 0 3 8 6 08 2 0 0 7 0 0 4 50 6 3 1 0 0 9 0 00 7 0 3 5 0 6 0 20 0 0 8 2 0 0 0 00 0 2 9 0 0 7 0 43 0 6 0 0 2 5 0 30 0 0 0 3 8 0 0 07 0 8 0 1 6 0 9 00 0 7 0 0 3 8 6 08 2 0 0 7 0 0 4 50 6 3 1 0 0 9 0 00 7 0 3 5 0 6 0 20 0 0 8 2 0 0 0 00 0 2 9 0 0 7 0 43 0 6 0 0 2 0 0 00 0 0 0 3 8 0 0 07 0 8 0 1 6 0 9 00 0 7 0 0 3 8 6 08 2 0 0 7 0 0 4 50 6 3 1 0 0 9 0 00 7 0 3 5 0 6 0 20 0 0 8 2 0 0 0 00 0 2 9 0 0 7 0 4'

def build_sample_text():
    values = []
    for token in RAW_SAMPLE.split():
        if len(token) == 1:
            values.append(int(token))
        else:
            values.extend(int(digit) for digit in token)
    assert values[0] == 3
    assert len(values) == 1 + 3 * 81
    lines = ["3"]
    for grid_index in range(3):
        grid = values[1 + grid_index * 81:1 + (grid_index + 1) * 81]
        for row in range(9):
            lines.append(" ".join(str(value) for value in grid[row * 9:row * 9 + 9]))
    return "\n".join(lines) + "\n"


SAMPLE = build_sample_text()


def solve_grid(grid, limit=2):
    row_used = [set() for _ in range(9)]
    col_used = [set() for _ in range(9)]
    box_used = [set() for _ in range(9)]
    for index in range(81):
        value = grid[index]
        if value:
            row = index // 9
            column = index % 9
            box = row // 3 * 3 + column // 3
            row_used[row].add(value)
            col_used[column].add(value)
            box_used[box].add(value)
    count = 0
    first_solution = None

    def visit(index):
        nonlocal count, first_solution
        while index < 81 and grid[index]:
            index += 1
        if index == 81:
            count += 1
            if count == 1:
                first_solution = list(grid)
            return
        row = index // 9
        column = index % 9
        box = row // 3 * 3 + column // 3
        used = row_used[row] | col_used[column] | box_used[box]
        for digit in range(1, 10):
            if digit in used:
                continue
            grid[index] = digit
            row_used[row].add(digit)
            col_used[column].add(digit)
            box_used[box].add(digit)
            visit(index + 1)
            row_used[row].discard(digit)
            col_used[column].discard(digit)
            box_used[box].discard(digit)
            grid[index] = 0
            if count >= limit:
                return

    visit(0)
    return count, first_solution


def parse_sample(text):
    values = []
    for token in text.split():
        if len(token) == 1:
            values.append(int(token))
        else:
            values.extend(int(digit) for digit in token)
    return values


def oracle(text):
    tokens = parse_sample(text)
    case_count = tokens[0]
    cursor = 1
    pieces = []
    for _ in range(case_count):
        grid = tokens[cursor:cursor + 81]
        cursor += 81
        count, solution = solve_grid(grid)
        lines = [str(count)]
        if count == 1:
            for row in range(9):
                lines.append(" ".join(str(value) for value in solution[row * 9:row * 9 + 9]))
        pieces.append("\n".join(lines))
    return "\n".join(pieces) + "\n"


BASE = [
    5, 3, 4, 6, 7, 8, 9, 1, 2,
    6, 7, 2, 1, 9, 5, 3, 4, 8,
    1, 9, 8, 3, 4, 2, 5, 6, 7,
    8, 5, 9, 7, 6, 1, 4, 2, 3,
    4, 2, 6, 8, 5, 3, 7, 9, 1,
    7, 1, 3, 9, 2, 4, 8, 5, 6,
    9, 6, 1, 5, 3, 7, 2, 8, 4,
    2, 8, 7, 4, 1, 9, 6, 3, 5,
    3, 4, 5, 2, 8, 6, 1, 7, 9,
]
assert solve_grid(BASE)[0] == 1
assert oracle(SAMPLE).startswith("1\n")
assert oracle(SAMPLE).count("\n") >= 11


def text_of(grids):
    text = str(len(grids)) + "\n"
    for grid in grids:
        text += "\n".join(" ".join(str(value) for value in grid[row * 9:row * 9 + 9]) for row in range(9)) + "\n\n"
    return text


def write(name, grids):
    text = text_of(grids)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_puzzle(rng, target_keep):
    grid = list(BASE)
    positions = list(range(81))
    rng.shuffle(positions)
    for position in positions:
        kept = sum(1 for value in grid if value)
        if kept <= target_keep:
            break
        original = grid[position]
        grid[position] = 0
        count, _ = solve_grid(grid, limit=3)
        if count > 2:
            grid[position] = original
    return grid


def build():
    rng = random.Random(20261126)
    conflicting = list(BASE)
    conflicting[1] = conflicting[0]
    write("2_edges", [list(BASE), conflicting, make_puzzle(rng, 30)])
    write("3_wide", [make_puzzle(rng, 28), make_puzzle(rng, 26), make_puzzle(rng, 24)])
    write("4_random", [make_puzzle(rng, rng.randint(24, 40)) for _ in range(6)])
    write("5_io", [make_puzzle(rng, 30) for _ in range(4)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE))
build()
