#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1234567


def cross_product(first, second, third):
    return ((second[0] - first[0]) * (third[1] - first[1])
            - (second[1] - first[1]) * (third[0] - first[0]))


def is_convex(points):
    ordered = sorted(points)
    if len(ordered) < 3:
        return False
    lower = []
    for point in ordered:
        while len(lower) >= 2 and cross_product(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper = []
    for point in reversed(ordered):
        while len(upper) >= 2 and cross_product(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    hull = lower[:-1] + upper[:-1]
    return len(hull) == len(ordered)


def oracle_case(points):
    total = 0
    for size in range(3, len(points) + 1):
        for subset in itertools.combinations(points, size):
            if is_convex(subset):
                total += 1
    return total % MODULUS


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    answers = []
    case_count = tokens[position]
    position += 1
    for _ in range(case_count):
        point_count = tokens[position]
        position += 1
        points = []
        for _ in range(point_count):
            points.append((tokens[position], tokens[position + 1]))
            position += 2
        answers.append(str(oracle_case(points)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
4
0 0
2 0
2 2
0 2
6
0 0
2 0
2 2
0 2
1 -1
1 3
"""
SAMPLE_OUT = """5
42
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n0 0\n1 0\n0 1\n") == "1\n"
assert oracle("1\n4\n0 0\n4 0\n2 4\n2 1\n") == "4\n"
assert oracle("1\n5\n0 0\n4 0\n2 4\n2 1\n3 1\n") == "11\n"


def random_points(count, rng):
    points = []
    while len(points) < count:
        candidate = (rng.randint(-100, 100), rng.randint(-100, 100))
        if candidate in points:
            continue
        if any(cross_product(points[i], points[j], candidate) == 0
               for i in range(len(points)) for j in range(i + 1, len(points))):
            continue
        points.append(candidate)
    return points


def write(name, cases):
    parts = [str(len(cases))]
    for points in cases:
        parts.append(str(len(points)))
        for point_x, point_y in points:
            parts.append(f"{point_x} {point_y}")
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        [(0, 0), (1, 0), (0, 1)],
        [(0, 0), (4, 0), (2, 4), (2, 1)],
        [(0, 0), (5, 0), (5, 5), (0, 5), (2, 1)],
    ])
    write("3_wide", [random_points(10, rng), random_points(11, rng),
                     random_points(12, rng), random_points(9, rng)])
    write("4_random", [random_points(rng.randint(3, 10), rng) for _ in range(20)])
    write("5_io", [random_points(rng.randint(3, 7), rng) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
