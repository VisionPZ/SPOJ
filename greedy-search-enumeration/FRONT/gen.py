#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    points = [(tokens[1 + 2 * index], tokens[2 + 2 * index])
              for index in range(count)]
    frontline = 0
    for point_index, (coord_x, coord_y) in enumerate(points):
        dominated = False
        for other_index, (other_x, other_y) in enumerate(points):
            if other_index == point_index:
                continue
            if other_x >= coord_x and other_y >= coord_y:
                dominated = True
                break
        if not dominated:
            frontline += 1
    return str(frontline) + "\n"


SAMPLE = """6
0 1
1 5
3 5
3 2
4 4
5 1
"""
assert oracle(SAMPLE) == "3\n"
assert oracle("1\n7 9\n") == "1\n"
assert oracle("2\n0 0\n1 1\n") == "1\n"
assert oracle("3\n0 10\n1 1\n2 9\n") == "2\n"
assert oracle("4\n0 4\n1 3\n2 2\n3 1\n") == "4\n"


def write(name, points):
    text = str(len(points)) + "\n" + "".join(
        "%d %d\n" % point for point in points)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(5, 1), (5, 4), (5, 2)])
    rng = random.Random(20261126)
    wide_x = sorted(rng.sample(range(10 ** 9), 200))
    write("3_wide", [(x, rng.randrange(10 ** 9)) for x in wide_x])
    random_x = sorted(rng.randrange(10 ** 9) for _ in range(300))
    write("4_random", [(x, rng.randrange(10 ** 9)) for x in random_x])
    write("5_io", [(index, 1000 - index) for index in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(0, 1), (1, 5), (3, 5), (3, 2), (4, 4), (5, 1)])
build()
