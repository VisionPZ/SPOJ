#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    rows = int(tokens[0])
    columns = int(tokens[1])
    grid = tokens[2:2 + rows]
    counts = [0] * (rows + 1)
    for column in range(columns):
        column_text = "".join(row[column] for row in grid)
        for run in re.findall("0+", column_text):
            counts[len(run)] += 1
    return "".join(
        f"{height} {counts[height]}\n"
        for height in range(1, rows + 1) if counts[height]
    )


SAMPLE = """5 10
1110000111
1100001111
1000000011
1111101111
1110000111
"""
SAMPLE_OUT = """1 7
2 1
3 2
5 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0\n") == "1 1\n"
assert oracle("1 3\n111\n") == ""
assert oracle("3 2\n000\n000\n000\n") == "3 2\n"
assert oracle("5 1\n0\n0\n1\n1\n0\n") == "1 1\n2 1\n"


def write(name, grid):
    text = f"{len(grid)} {len(grid[0])}\n" + "\n".join(grid) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["0000", "1111", "0011", "1000"])
    write("3_wide", [
        "".join("0" if (column + row) % 7 == 0 else "1" for column in range(200))
        for row in range(199)
    ])
    rng = random.Random(20261126)
    write("4_random", [
        "".join("0" if rng.random() < 0.4 else "1" for _ in range(200))
        for _ in range(199)
    ])
    write("5_io", [
        "".join("0" if row <= column else "1" for column in range(200))
        for row in range(200)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
