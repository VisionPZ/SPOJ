#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def simulate(source, row_cut, left_cut, right_cut):
    size = len(source)
    grid = [list(row) for row in source]
    for column in range(size):
        for offset in range((row_cut + 1) // 2):
            grid[offset][column], grid[row_cut - offset][column] = \
                grid[row_cut - offset][column], grid[offset][column]
    for row in grid:
        for offset in range((left_cut + 1) // 2):
            row[offset], row[left_cut - offset] = row[left_cut - offset], row[offset]
        for column in range(right_cut, (size + right_cut) // 2):
            row[column], row[size + right_cut - 1 - column] = \
                row[size + right_cut - 1 - column], row[column]
        row[:] = row[left_cut + 1:] + row[:left_cut + 1]
    return ["".join(row) for row in grid]


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    size = int(lines[0])
    source = lines[1:1 + size]
    target = lines[1 + size:1 + 2 * size]
    for row_cut in range(size - 2, 0, -1):
        for left_cut in range(size - 2, -1, -1):
            for right_cut in range(size - 1, left_cut, -1):
                if simulate(source, row_cut, left_cut, right_cut) == target:
                    return f"{row_cut} {left_cut} {right_cut}\n"
    raise AssertionError("no triplet found")


SAMPLE = """5
ooscz
hkaea
nnzth
khdlf
rejtf
fldhk
htznn
aeakh
zcsoo
ftjer
"""
SAMPLE_OUT = "3 3 4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert simulate(["abcd", "efgh", "ijkl", "mnop"],
                1, 0, 1) == ["hgfe", "dcba", "lkji", "ponm"]


def write(name, source, row_cut, left_cut, right_cut):
    target = simulate(source, row_cut, left_cut, right_cut)
    lines = [str(len(source))] + source + target
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    alphabet = "abcdef"
    small = ["".join(rng.choice(alphabet) for _ in range(5)) for _ in range(5)]
    write("2_edges", small, 1, 0, 1)

    wide = ["".join(rng.choice(alphabet) for _ in range(1000)) for _ in range(1000)]
    write("3_wide", wide, 998, 998, 999)

    size = rng.randint(6, 18)
    random_grid = ["".join(rng.choice(alphabet) for _ in range(size)) for _ in range(size)]
    row_cut = rng.randint(1, size - 2)
    left_cut = rng.randint(0, size - 2)
    right_cut = rng.randint(left_cut + 1, size - 1)
    write("4_random", random_grid, row_cut, left_cut, right_cut)

    big = ["".join(rng.choice(alphabet) for _ in range(1000)) for _ in range(1000)]
    write("5_io", big, 998, 998, 999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
