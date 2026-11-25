#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(points):
    best = 0
    for _, _, quality in points:
        if quality > best:
            best = quality
    for first in range(len(points)):
        base_x, base_y, _ = points[first]
        for second in range(first + 1, len(points)):
            other_x, other_y, _ = points[second]
            delta_x = other_x - base_x
            delta_y = other_y - base_y
            total = 0
            for point_x, point_y, quality in points:
                if (point_x - base_x) * delta_y == (point_y - base_y) * delta_x:
                    total += quality
            if total > best:
                best = total
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        point_count = tokens[cursor]
        cursor += 1
        points = [(tokens[cursor + index * 3], tokens[cursor + index * 3 + 1],
                   tokens[cursor + index * 3 + 2]) for index in range(point_count)]
        cursor += 3 * point_count
        answers.append(str(oracle_case(points)))
    return "\n".join(answers) + "\n"


SAMPLE_ONE = """5
4
0 0 1
1 1 1
2 2 1
3 3 1
5
0 0 -10
1 0 2
0 1 3
-1 0 2
0 -1 3
3
0 0 -1
1 1 -2
1 3 -5
2
0 0 666
1 7 -666
5
0 0 1
99999999 0 6
0 99999999 5
-99999999 0 6
0 -99999999 5
"""
SAMPLE_ONE_OUT = """4
5
0
666
13
"""
SAMPLE_TWO = """1
7
10 8 -2
9 4 -1
-3 -5 -5
7 5 1
-3 2 -6
5 10 -4
9 7 10
"""
SAMPLE_TWO_OUT = "10\n"
SAMPLE_THREE = """1
4
-6 0 9
7 4 7
7 -6 -10
-6 7 10
"""
SAMPLE_THREE_OUT = "19\n"
SAMPLE_FOUR = """1
6
-10 -1 -10
8 3 4
0 9 -2
4 -6 1
6 0 10
-6 1 -10
"""
SAMPLE_FOUR_OUT = "14\n"
assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle(SAMPLE_THREE) == SAMPLE_THREE_OUT
assert oracle(SAMPLE_FOUR) == SAMPLE_FOUR_OUT
assert oracle_case([(0, 0, 5)]) == 5
assert oracle_case([(0, 0, -5), (1, 1, -2)]) == 0
assert oracle_case([(0, 0, 3), (1, 0, 4), (2, 0, 5)]) == 12


def random_points(rng, count, bound):
    seen = set()
    while len(seen) < count:
        seen.add((rng.randint(-bound, bound), rng.randint(-bound, bound)))
    return [(x, y, rng.randint(-10000, 10000)) for x, y in sorted(seen)]


def write(name, cases):
    parts = [str(len(cases))]
    for points in cases:
        parts.append(str(len(points)))
        parts.extend(f"{x} {y} {quality}" for x, y, quality in points)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [(0, 0, 5)],
        [(0, 0, -5), (1, 1, -2)],
        [(0, 0, 3), (1, 0, 4), (2, 0, 5), (3, 0, -1)],
        [(-1000000000, -1000000000, 10000), (1000000000, 1000000000, 10000)],
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_points(rng, 120, 1000000000)])
    write("4_random", [random_points(rng, rng.randint(20, 100), 1000)
                       for _ in range(4)])
    write("5_io", [random_points(rng, rng.randint(2, 25), 100)
                   for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_ONE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_ONE_OUT)
build()
