#!/usr/bin/env python3
import random
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE = """3 4 6
12 30 12 100 22 -1
30 12 5 3
12 30 100 5
22 3 22 100
3 4 6
2 30 12 100 22 -1
30 12 5 3
12 30 100 5
22 3 22 100
3 4 6
12 30 12 100 22 -1
30 12 5 3
12 30 100 5
22 12 22 100
0 0 0
"""
SAMPLE_OUT = """4 1 1 2 3
0 1 1 1 1
5 1 2 3 3
"""


def oracle_case(rows, columns, area_limit, medicines, grid):
    length = len(medicines)
    needed = [Counter()]
    for value in medicines:
        current = needed[-1].copy()
        current[value] += 1
        needed.append(current)
    best = (0, 1, 1, 1, 1)
    for top in range(1, rows + 1):
        for left in range(1, columns + 1):
            for bottom in range(top, rows + 1):
                for right in range(left, columns + 1):
                    if (bottom - top + 1) * (right - left + 1) > area_limit:
                        continue
                    available = Counter()
                    for row in range(top, bottom + 1):
                        for column in range(left, right + 1):
                            available[grid[row - 1][column - 1]] += 1
                    survived = 0
                    for day in range(1, length + 1):
                        if all(available[key] >= amount
                               for key, amount in needed[day].items()):
                            survived = day
                        else:
                            break
                    if survived > best[0]:
                        best = (survived, top, left, bottom, right)
    return best


def oracle(text):
    tokens = iter(int(value) for value in text.split())
    lines = []
    while True:
        rows = next(tokens)
        columns = next(tokens)
        area_limit = next(tokens)
        if rows == 0 and columns == 0 and area_limit == 0:
            break
        medicines = []
        while True:
            value = next(tokens)
            if value == -1:
                break
            medicines.append(value)
        grid = [[next(tokens) for _ in range(columns)] for _ in range(rows)]
        best = oracle_case(rows, columns, area_limit, medicines, grid)
        lines.append(" ".join(str(value) for value in best))
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 1\n-1\n7\n0 0 0\n") == "0 1 1 1 1\n"
assert oracle("1 1 1\n7 -1\n7\n0 0 0\n") == "1 1 1 1 1\n"
assert oracle("1 1 1\n8 -1\n7\n0 0 0\n") == "0 1 1 1 1\n"
assert oracle("2 1 2\n7 7 -1\n7\n7\n0 0 0\n") == "2 1 1 2 1\n"


def build_case(rows, columns, area_limit, medicines, grid):
    lines = [f"{rows} {columns} {area_limit}",
             " ".join(str(value) for value in medicines) + " -1"]
    lines.extend(" ".join(str(value) for value in row) for row in grid)
    lines.append("0 0 0")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = "".join(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        build_case(1, 1, 1, [], [[7]]),
        build_case(1, 1, 1, [7], [[7]]),
        build_case(1, 1, 1, [8], [[7]]),
        build_case(2, 1, 2, [7, 7], [[7], [7]]),
        build_case(2, 2, 3, [1, 2], [[1, 2], [2, 1]]),
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(5):
        rows, columns = 12, 12
        medicines = [rng.randint(1, 8) for _ in range(8)]
        grid = [[rng.randint(1, 8) for _ in range(columns)] for _ in range(rows)]
        wide.append(build_case(rows, columns, 16, medicines, grid))
    write("3_wide", wide)
    random_cases = []
    for _ in range(20):
        rows = rng.randint(1, 10)
        columns = rng.randint(1, 10)
        medicines = [rng.randint(1, 6) for _ in range(rng.randint(0, 8))]
        grid = [[rng.randint(1, 6) for _ in range(columns)] for _ in range(rows)]
        random_cases.append(build_case(rows, columns, rng.randint(2, 14), medicines, grid))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(120):
        rows = rng.randint(2, 6)
        columns = rng.randint(2, 6)
        medicines = [rng.randint(1, 5) for _ in range(rng.randint(1, 6))]
        grid = [[rng.randint(1, 5) for _ in range(columns)] for _ in range(rows)]
        io_cases.append(build_case(rows, columns, rng.randint(2, 6), medicines, grid))
    write("5_io", io_cases)
    with open("/tmp/FCATTLE_big.txt", "w") as handle:
        rows, columns = 200, 200
        medicines = [rng.randint(1, 20) for _ in range(20)]
        handle.write(f"{rows} {columns} 25\n")
        handle.write(" ".join(str(value) for value in medicines) + " -1\n")
        for _ in range(rows):
            handle.write(" ".join(str(rng.randint(1, 20)) for _ in range(columns)) + "\n")
        handle.write("0 0 0\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
