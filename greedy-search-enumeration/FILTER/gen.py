#!/usr/bin/env python3
from functools import lru_cache
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


@lru_cache(maxsize=None)
def build_out_table(width):
    row_values = 1 << width
    counts = [[0] * width for _ in range(row_values)]
    for value in range(row_values):
        for column in range(width):
            left = max(0, column - 1)
            right = min(width - 1, column + 1)
            counts[value][column] = ((value >> left) & 1) + ((value >> column) & 1) + ((value >> right) & 1)
    by_pair = {}
    for upper in range(row_values):
        cu = counts[upper]
        for middle in range(row_values):
            cm = counts[middle]
            sum_um = [cu[c] + cm[c] for c in range(width)]
            bucket = {}
            for lower in range(row_values):
                cl = counts[lower]
                filtered = 0
                for column in range(width):
                    if sum_um[column] + cl[column] >= 5:
                        filtered |= 1 << column
                bucket.setdefault(filtered, []).append(lower)
            by_pair[(upper, middle)] = bucket
    return by_pair


def dp_oracle(width, height, target_rows):
    if width * height <= 12:
        target = [[(value >> column) & 1 for column in range(width)] for value in target_rows]
        return brute(width, height, target)
    row_values = 1 << width
    by_pair = build_out_table(width)
    black_counts = [bin(value).count("1") for value in range(row_values)]
    if height == 1:
        possibilities = []
        for value in range(row_values):
            if value in by_pair[(value, value)].get(target_rows[0], ()):
                possibilities.append(black_counts[value])
        if not possibilities:
            return "Impossible"
        return str(max(possibilities) - min(possibilities))
    state = {}
    t0 = target_rows[0]
    for upper in range(row_values):
        for lower in by_pair[(upper, upper)].get(t0, ()):
            cost = black_counts[upper] + black_counts[lower]
            key = (upper, lower)
            if key not in state:
                state[key] = [cost, cost]
            else:
                if cost < state[key][0]: state[key][0] = cost
                if cost > state[key][1]: state[key][1] = cost
    for row_index in range(1, height - 1):
        new_state = {}
        target_r = target_rows[row_index]
        for (upper, middle), (mn, mx) in state.items():
            for lower in by_pair[(upper, middle)].get(target_r, ()):
                cmin = mn + black_counts[lower]
                cmax = mx + black_counts[lower]
                key = (middle, lower)
                prev = new_state.get(key)
                if prev is None:
                    new_state[key] = [cmin, cmax]
                else:
                    if cmin < prev[0]: prev[0] = cmin
                    if cmax > prev[1]: prev[1] = cmax
        state = new_state
    best_min = None
    best_max = None
    last_t = target_rows[height - 1]
    for (upper, middle), (mn, mx) in state.items():
        if middle in by_pair[(upper, middle)].get(last_t, ()):
            if best_min is None or mn < best_min: best_min = mn
            if best_max is None or mx > best_max: best_max = mx
    if best_min is None:
        return "Impossible"
    return str(best_max - best_min)


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
