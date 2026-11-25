#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    row_count = int(tokens[0])
    column_count = int(tokens[1])
    grid = tokens[2:2 + row_count]
    total = row_count * column_count
    parent = list(range(total))

    def find(cell):
        while parent[cell] != cell:
            parent[cell] = parent[parent[cell]]
            cell = parent[cell]
        return cell

    def union(first, second):
        first_root = find(first)
        second_root = find(second)
        if first_root != second_root:
            parent[first_root] = second_root

    for row in range(row_count):
        for column in range(column_count):
            cell = row * column_count + column
            if grid[row][column] == '#':
                continue
            if row + 1 < row_count and grid[row + 1][column] != '#':
                union(cell, cell + column_count)
            if column + 1 < column_count and grid[row][column + 1] != '#':
                union(cell, cell + 1)

    sectors = {}
    for row in range(row_count):
        for column in range(column_count):
            cell = row * column_count + column
            if grid[row][column] == '#':
                continue
            root = find(cell)
            entry = sectors.setdefault(root, [0, 0, False])
            if grid[row][column] == 'k':
                entry[0] += 1
            elif grid[row][column] == 'v':
                entry[1] += 1
            if row in (0, row_count - 1) or column in (0, column_count - 1):
                entry[2] = True

    sheep = 0
    wolves = 0
    for sector_sheep, sector_wolves, escapes in sectors.values():
        if escapes:
            sheep += sector_sheep
            wolves += sector_wolves
        elif sector_sheep > sector_wolves:
            sheep += sector_sheep
        else:
            wolves += sector_wolves
    return f"{sheep} {wolves}\n"


SAMPLE = """8 8
.######.
#..k...#
#.####.#
#.#v.#.#
#.#.k#k#
#k.##..#
#.v..v.#
.######.
"""
SAMPLE_OUT = "3 1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 3\n...\n.kv.\n...\n") == "1 1\n"
assert oracle("3 3\n###\n#k#\n###\n") == "1 0\n"
assert oracle("3 3\n###\n#v#\n###\n") == "0 1\n"
assert 3 * 8 + 5 == 29


def write(name, rows):
    text = f"{len(rows)} {len(rows[0])}\n" + "\n".join(rows) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("1_sample", SAMPLE.strip("\n").split("\n")[1:])
    write("2_edges", ["..." ] * 3)
    write("3_wide", ["#####", "#kkk#", "#vvv#", "#k.k#", "#####"])
    rng = random.Random(20261126)
    alphabet = ".#kv"
    write("4_random", ["".join(rng.choice(alphabet) for _ in range(9)) for _ in range(9)])
    write("5_io", ["".join(rng.choice(".kv#") for _ in range(250)) for _ in range(250)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
