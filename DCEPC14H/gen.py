#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_grid(text):
    lines = text.replace("\r", "").strip().split("\n")
    size = int(lines[0])
    return size, lines[1:1 + size]


def is_blocker(character):
    return character == "#" or character == "T"


def find_segments(grid, size):
    horizontal_weights = []
    vertical_weights = []
    horizontal_id = [[-1] * size for _ in range(size)]
    vertical_id = [[-1] * size for _ in range(size)]

    for row in range(size):
        column = 0
        while column < size:
            if is_blocker(grid[row][column]):
                column += 1
                continue
            start = column
            while column < size and not is_blocker(grid[row][column]):
                column += 1
            end = column - 1
            left_tower = start > 0 and grid[row][start - 1] == "T"
            right_tower = end < size - 1 and grid[row][end + 1] == "T"
            if left_tower or right_tower:
                index = len(horizontal_weights)
                total = sum(int(grid[row][cell]) for cell in range(start, end + 1) if grid[row][cell] != "0")
                horizontal_weights.append(total)
                for cell in range(start, end + 1):
                    horizontal_id[row][cell] = index

    for column in range(size):
        row = 0
        while row < size:
            if is_blocker(grid[row][column]):
                row += 1
                continue
            start = row
            while row < size and not is_blocker(grid[row][column]):
                row += 1
            end = row - 1
            top_tower = start > 0 and grid[start - 1][column] == "T"
            bottom_tower = end < size - 1 and grid[end + 1][column] == "T"
            if top_tower or bottom_tower:
                index = len(vertical_weights)
                total = sum(int(grid[cell][column]) for cell in range(start, end + 1) if grid[cell][column] != "0")
                vertical_weights.append(total)
                for cell in range(start, end + 1):
                    vertical_id[cell][column] = index

    conflicts = [set() for _ in horizontal_weights]
    for row in range(size):
        for column in range(size):
            horizontal = horizontal_id[row][column]
            vertical = vertical_id[row][column]
            if horizontal >= 0 and vertical >= 0:
                conflicts[horizontal].add(vertical)
    return horizontal_weights, vertical_weights, conflicts


def oracle(text):
    size, grid = parse_grid(text)
    horizontal_weights, vertical_weights, conflicts = find_segments(grid, size)
    best = 0
    for mask in range(1 << len(horizontal_weights)):
        score = 0
        blocked = set()
        for horizontal in range(len(horizontal_weights)):
            if mask & (1 << horizontal):
                score += horizontal_weights[horizontal]
                blocked.update(conflicts[horizontal])
        for vertical in range(len(vertical_weights)):
            if vertical not in blocked:
                score += vertical_weights[vertical]
        best = max(best, score)
    return str(best) + "\n"


SAMPLE = """4
T000
1#T3
292T
9000
"""
SAMPLE_OUT = """17
"""
SECOND = """4
T000
1003
292T
9000
"""
SECOND_OUT = """16
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == SECOND_OUT
assert oracle("2\n00\n00\n") == "0\n"
assert oracle("2\nT1\n00\n") == "1\n"
assert oracle("2\nT1\n11\n") == "2\n"
assert oracle("3\nT11\n111\n111\n") == "4\n"


def write(name, grid):
    text = str(len(grid)) + "\n" + "\n".join(grid) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_grid(rng, size, tower_count, wall_rate):
    cells = [[rng.choice("000000123456789") for _ in range(size)] for _ in range(size)]
    spots = rng.sample(range(size * size), min(tower_count, size * size))
    for spot in spots:
        cells[spot // size][spot % size] = "T"
    for row in range(size):
        for column in range(size):
            if cells[row][column] != "T" and rng.random() < wall_rate:
                cells[row][column] = "#"
    return ["".join(row) for row in cells]


def build():
    write("2_edges", ["T1", "00"])
    rng = random.Random(20261126)
    write("3_wide", random_grid(rng, 500, 8, 0.01))
    write("4_random", random_grid(rng, 9, 4, 0.05))
    write("5_io", random_grid(rng, 300, 6, 0.02))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
