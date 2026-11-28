#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        size = int(tokens[cursor])
        cursor += 1
        grid = []
        for _ in range(size):
            grid.append(tokens[cursor])
            cursor += 1
        total = 0
        for top in range(size):
            for bottom in range(top, size):
                for left in range(size):
                    for right in range(left, size):
                        valid = True
                        for row in range(max(0, top - 1), min(size, bottom + 2)):
                            for col in range(max(0, left - 1), min(size, right + 2)):
                                if grid[row][col] != 'X':
                                    continue
                                inside = top <= row <= bottom and left <= col <= right
                                strict = top < row < bottom and left < col < right
                                side = ((row in (top - 1, bottom + 1) and left <= col <= right)
                                        or (col in (left - 1, right + 1)
                                            and top <= row <= bottom))
                                if side or (inside and not strict):
                                    valid = False
                        if valid:
                            total += 1
        answers.append(str(total))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """4
3
...
.X.
...
3
X..
...
X..
6
......
......
......
......
......
......
5
.....
....X
.X...
.....
...XX
"""
SAMPLE_OUT = """5
8
441
23
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n.\n") == "1\n"
assert oracle("1\n2\n..\n..\n") == "9\n"
assert oracle("1\n3\n...\n.X.\n...\n") == "5\n"
assert oracle("1\n3\nX..\n...\nX..\n") == "8\n"
assert oracle("2\n1\n.\n6\n" + "......\n" * 6) == "1\n441\n"


def case(grid):
    size = len(grid)
    return str(size) + "\n" + "\n".join(grid) + "\n"


def write(name, grids):
    text = str(len(grids)) + "\n" + "".join(case(grid) for grid in grids)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [["..", "X."], [".X", "X."], ["...", "...", "X.X"]])
    write("3_wide", [["......"] * 6, ["....."] * 5])
    rng = random.Random(20261126)
    random_grid = [
        "".join('X' if rng.random() < 0.2 else '.' for _ in range(8))
        for _ in range(8)
    ]
    write("4_random", [random_grid])
    many_grids = []
    for _ in range(120):
        many_grids.append([
            "".join('X' if rng.random() < 0.25 else '.' for _ in range(3))
            for _ in range(3)
        ])
    write("5_io", many_grids)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
