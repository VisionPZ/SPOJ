#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    point_count = tokens[0]
    points = [(tokens[1 + 2 * index], tokens[2 + 2 * index]) for index in range(point_count)]
    columns = {}
    for x_coord, y_coord in points:
        columns.setdefault(x_coord, set()).add(y_coord)
    x_values = sorted(columns)
    total = 0
    for first_index in range(len(x_values)):
        for second_index in range(first_index + 1, len(x_values)):
            shared = len(columns[x_values[first_index]] & columns[x_values[second_index]])
            total += shared * (shared - 1) // 2
    return str(total) + "\n"


SAMPLE = """6
-1 0
-1 1
0 0
0 1
1 0
1 1
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5 7\n") == "0\n"
assert oracle("4\n0 0\n0 1\n1 0\n1 1\n") == "1\n"
assert oracle("9\n0 0\n0 1\n0 2\n1 0\n1 1\n1 2\n2 0\n2 1\n2 2\n") == "9\n"
assert oracle("6\n0 0\n0 1\n1 0\n2 0\n2 1\n1 1\n") == "3\n"
assert 64 * (64 - 1) // 2 == 2016


def case(points):
    return str(len(points)) + "\n" + "".join(f"{x} {y}\n" for x, y in points)


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", case([(0, 0), (0, 1), (1, 0), (1, 1), (5, 5), (5, 9), (8, 5), (8, 9)]))
    write("3_wide", case([(x, y) for x in range(-5, 5) for y in range(-5, 5)]))
    rng = random.Random(20261126)
    points = set()
    while len(points) < 150:
        points.add((rng.randint(-30, 30), rng.randint(-30, 30)))
    write("4_random", case(sorted(points)))
    grid = [(x, y) for x in range(64) for y in range(64)]
    write("5_io", case(grid))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
