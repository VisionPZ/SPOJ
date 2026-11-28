#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]; cursor += 1
    answers = []
    for _ in range(case_count):
        row_count = tokens[cursor]
        col_count = tokens[cursor + 1]
        capacity = tokens[cursor + 2]
        cursor += 3
        grid = []
        for _ in range(row_count):
            grid.append(tokens[cursor:cursor + col_count])
            cursor += col_count
        sums = [[set() for _ in range(col_count)] for _ in range(row_count)]
        if grid[0][0] <= capacity:
            sums[0][0].add(grid[0][0])
        for row in range(row_count):
            for col in range(col_count):
                if row == 0 and col == 0:
                    continue
                reachable = set()
                sources = []
                if col > 0:
                    sources.append(sums[row][col - 1])
                if row > 0:
                    sources.append(sums[row - 1][col])
                if row > 0 and col > 0:
                    sources.append(sums[row - 1][col - 1])
                for source in sources:
                    for value in source:
                        candidate = value + grid[row][col]
                        if candidate <= capacity:
                            reachable.add(candidate)
                sums[row][col] = reachable
        finals = sums[row_count - 1][col_count - 1]
        answers.append(str(max(finals)) if finals else "-1")
    return "\n".join(answers) + "\n"


SAMPLE = """2
3 3 7
2 3 1
6 1 9
8 2 3
3 4 9
2 3 4 1
6 5 5 3
5 2 3 4
"""
SAMPLE_OUT = """6
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 50\n50\n") == "50\n"
assert oracle("1\n1 1 49\n50\n") == "-1\n"
assert oracle("1\n3 1 100\n10\n20\n30\n") == "60\n"
assert oracle("1\n1 3 100\n10 20 30\n") == "60\n"
assert oracle("1\n2 2 1\n1 1\n1 1\n") == "-1\n"
assert oracle("1\n2 2 2\n1 1\n1 1\n") == "2\n"


def case_text(grid, capacity):
    rows = len(grid)
    cols = len(grid[0])
    return (f"{rows} {cols} {capacity}\n" +
            "".join(" ".join(str(value) for value in row) + "\n" for row in grid))


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(case_text(grid, capacity)
                                             for grid, capacity in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([[50]], 50), ([[50]], 49), ([[1]], 1),
        ([[10], [20], [30]], 60), ([[10, 20, 30]], 60),
        ([[1, 1], [1, 1]], 2),
    ])
    write("3_wide", [
        ([[50] * 10 for _ in range(10)], 5000),
        ([[50]] * 100, 5000),
    ])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(10):
        rows = rng.randrange(1, 9)
        cols = rng.randrange(1, 9)
        grid = [[rng.randrange(1, 51) for _ in range(cols)] for _ in range(rows)]
        random_cases.append((grid, rng.randrange(1, 5001)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        grid = [[rng.randrange(1, 51) for _ in range(10)] for _ in range(10)]
        io_cases.append((grid, 5000))
    write("5_io", io_cases)
    big_cases = []
    for _ in range(10):
        grid = [[rng.randrange(1, 51) for _ in range(100)] for _ in range(100)]
        big_cases.append((grid, 5000))
    Path("/tmp/SHUB1307_big.txt").write_text(
        str(len(big_cases)) + "\n" +
        "".join(case_text(grid, capacity) for grid, capacity in big_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    ([[2, 3, 1], [6, 1, 9], [8, 2, 3]], 7),
    ([[2, 3, 4, 1], [6, 5, 5, 3], [5, 2, 3, 4]], 9),
])
build()
