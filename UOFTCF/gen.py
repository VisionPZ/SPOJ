#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def solve_grid(grid):
    row_count = len(grid)
    column_count = len(grid[0])
    best = [-1]

    def walk(row, alice, bob, held):
        if row == row_count:
            if held > best[0]:
                best[0] = held
            return
        for next_alice in range(max(0, alice - 1), min(column_count, alice + 2)):
            if grid[row][next_alice] != ".":
                continue
            for next_bob in range(max(0, bob - 1), min(column_count, bob + 2)):
                if grid[row][next_bob] != "." or next_alice == next_bob:
                    continue
                gain = 1 if abs(next_alice - next_bob) == 1 else 0
                walk(row + 1, next_alice, next_bob, held + gain)

    for alice in range(column_count):
        if grid[0][alice] != ".":
            continue
        for bob in range(column_count):
            if bob == alice or grid[0][bob] != ".":
                continue
            gain = 1 if abs(alice - bob) == 1 else 0
            walk(1, alice, bob, gain)
    return "Detour" if best[0] < 0 else str(best[0])


def oracle(text):
    tokens = text.split()
    position = 0
    sidewalk_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(sidewalk_count):
        rows = int(tokens[position])
        columns = int(tokens[position + 1])
        position += 2
        grid = tokens[position:position + rows]
        position += rows
        answers.append(solve_grid(grid))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """2
5 5
#....
..##.
.#...
#.#..
....#
2 4
.##.
..##
"""
SAMPLE_OUT = """4
Detour
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 2\n..\n") == "1\n"
assert oracle("1\n2 2\n#.\n.#\n") == "Detour\n"
assert oracle("1\n3 2\n..\n..\n..\n") == "3\n"
assert oracle("1\n2 4\n....\n....\n") == "2\n"


def write(name, grids):
    lines = [str(len(grids))]
    for grid in grids:
        lines.append(f"{len(grid)} {len(grid[0])}")
        lines.extend(grid)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_grid(rng, rows, columns):
    return ["".join("." if rng.random() < 0.75 else "#" for _ in range(columns))
            for _ in range(rows)]


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        ["..", ".."],
        ["#.", ".#"],
        [".#", "#."],
        ["...."],
        ["##..", "..##"],
    ])
    write("3_wide", [random_grid(rng, 2, 20), random_grid(rng, 3, 18)])
    write("4_random", [random_grid(rng, rng.randint(1, 4), rng.randint(2, 7))
                       for _ in range(5)])
    write("5_io", [random_grid(rng, 3, 6) for _ in range(12)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    ["#....", "..##.", ".#...", "#.#..", "....#"],
    [".##.", "..##"],
])
build()
