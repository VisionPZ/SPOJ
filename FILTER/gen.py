#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def filter_image(width, height, pixels):
    result = []
    for row in range(height):
        line = []
        for column in range(width):
            ones = 0
            for near_row in (row - 1, row, row + 1):
                used_row = min(max(near_row, 0), height - 1)
                for near_column in (column - 1, column, column + 1):
                    used_column = min(max(near_column, 0), width - 1)
                    ones += pixels[used_row][used_column]
            line.append(1 if ones >= 5 else 0)
        result.append(line)
    return result


def brute(width, height, target):
    cells = width * height
    best_min = None
    best_max = None
    for code in range(1 << cells):
        pixels = [[(code >> (row * width + column)) & 1 for column in range(width)] for row in range(height)]
        if filter_image(width, height, pixels) != target:
            continue
        black = sum(sum(row) for row in pixels)
        if best_min is None or black < best_min:
            best_min = black
        if best_max is None or black > best_max:
            best_max = black
    if best_min is None:
        return "Impossible"
    return str(best_max - best_min)


def build_out_table(width):
    row_values = 1 << width
    counts = [[0] * width for _ in range(row_values)]
    for value in range(row_values):
        for column in range(width):
            left = max(0, column - 1)
            right = min(width - 1, column + 1)
            counts[value][column] = ((value >> left) & 1) + ((value >> column) & 1) + ((value >> right) & 1)
    table = [[0] * row_values for _ in range(row_values * row_values)]
    for upper in range(row_values):
        for middle in range(row_values):
            base = upper * row_values + middle
            for lower in range(row_values):
                filtered = 0
                for column in range(width):
                    if counts[upper][column] + counts[middle][column] + counts[lower][column] >= 5:
                        filtered |= 1 << column
                table[base][lower] = filtered
    return table


def dp_oracle(width, height, target_rows):
    if width * height <= 12:
        target = [[(value >> column) & 1 for column in range(width)] for value in target_rows]
        return brute(width, height, target)
    row_values = 1 << width
    table = build_out_table(width)
    black_counts = [bin(value).count("1") for value in range(row_values)]
    if height == 1:
        possibilities = []
        for value in range(row_values):
            if table[value * row_values + value][value] == target_rows[0]:
                possibilities.append(black_counts[value])
        if not possibilities:
            return "Impossible"
        return str(max(possibilities) - min(possibilities))
    minimum = [[None] * row_values for _ in range(row_values)]
    maximum = [[None] * row_values for _ in range(row_values)]
    for upper in range(row_values):
        for lower in range(row_values):
            if table[upper * row_values + upper][lower] == target_rows[0]:
                cost = black_counts[upper] + black_counts[lower]
                old_min = minimum[upper][lower]
                minimum[upper][lower] = cost if old_min is None else min(old_min, cost)
                old_max = maximum[upper][lower]
                maximum[upper][lower] = cost if old_max is None else max(old_max, cost)
    for row_index in range(1, height - 1):
        new_min = [[None] * row_values for _ in range(row_values)]
        new_max = [[None] * row_values for _ in range(row_values)]
        for upper in range(row_values):
            for middle in range(row_values):
                if minimum[upper][middle] is None:
                    continue
                for lower in range(row_values):
                    if table[upper * row_values + middle][lower] != target_rows[row_index]:
                        continue
                    cost_min = minimum[upper][middle] + black_counts[lower]
                    cost_max = maximum[upper][middle] + black_counts[lower]
                    slot_min = new_min[middle][lower]
                    new_min[middle][lower] = cost_min if slot_min is None else min(slot_min, cost_min)
                    slot_max = new_max[middle][lower]
                    new_max[middle][lower] = cost_max if slot_max is None else max(slot_max, cost_max)
        minimum, maximum = new_min, new_max
    answers = []
    for upper in range(row_values):
        for middle in range(row_values):
            if minimum[upper][middle] is None:
                continue
            if table[upper * row_values + middle][middle] == target_rows[height - 1]:
                answers.append((minimum[upper][middle], maximum[upper][middle]))
    if not answers:
        return "Impossible"
    return str(max(value[1] for value in answers) - min(value[0] for value in answers))


def encode(rows):
    return [sum((1 << column) for column, char in enumerate(row) if char == "#") for row in rows]


def input_text(cases):
    parts = []
    for width, height, rows in cases:
        parts.append(f"{width} {height}\n")
        parts.extend(row + "\n" for row in rows)
    return "".join(parts) + "0 0\n"


def oracle_text(cases):
    return "".join(f"Case {number}: {dp_oracle(width, height, encode(rows))}\n"
                   for number, (width, height, rows) in enumerate(cases, 1))


SAMPLE_CASES = [
    (5, 5, ["#####"] * 5),
    (4, 4, ["####"] * 4),
    (4, 4, ["#...", "....", "....", "...#"]),
    (4, 4, [".#.#", "#.#.", ".#.#", "#.#."]),
]
SAMPLE_IN = input_text(SAMPLE_CASES)
SAMPLE_OUT = "Case 1: 10\nCase 2: 6\nCase 3: 2\nCase 4: Impossible\n"
assert dp_oracle(5, 5, encode(SAMPLE_CASES[0][2])) == "10"
assert dp_oracle(4, 4, encode(SAMPLE_CASES[1][2])) == "6"
assert dp_oracle(4, 4, encode(SAMPLE_CASES[2][2])) == "2"
assert dp_oracle(4, 4, encode(SAMPLE_CASES[3][2])) == "Impossible"
assert dp_oracle(1, 1, [0]) == "0"
assert dp_oracle(2, 2, [0, 0]) == "1"
assert dp_oracle(2, 2, [3, 3]) == "1"
assert oracle_text(SAMPLE_CASES) == SAMPLE_OUT


def write(name, cases):
    (ROOT / "in" / f"{name}.txt").write_text(input_text(cases))
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


def build():
    write("2_edges", [(1, 1, ["#"]), (1, 1, ["."]), (2, 2, ["##", "##"]),
                      (2, 2, ["..", ".."]), (3, 3, ["#.#", "...", "#.#"])])
    write("3_wide", [(8, 8, ["########"] * 8), (8, 8, ["........"] * 8),
                     (8, 8, ["#.#.#.#." if row % 2 == 0 else ".#.#.#.#" for row in range(8)])])
    rng = random.Random(20261126)
    random_cases = []
    for number in range(10):
        width = rng.randint(1, 6)
        height = rng.randint(1, 6)
        rows = ["".join(rng.choice("#.") for _ in range(width)) for _ in range(height)]
        random_cases.append((width, height, rows))
    write("4_random", random_cases)
    io_cases = []
    for number in range(16):
        width = 8
        height = 8
        rows = ["".join(rng.choice("#.") for _ in range(width)) for _ in range(height)]
        io_cases.append((width, height, rows))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
