#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """4
3
0 3 3
4 0 4
-3 -4 5
3
0 10 2
0 20 2
0 40 2
3
0 100 15
0 -100 15
8 0 7
3
0 0 1
10000 0 1
5000 8661 1
"""
SAMPLE_OUT = """1.000000
7.500000
6.666667
5773.751357
"""


def circle_crossings(first, second, radius_first, radius_second):
    dx = second[0] - first[0]
    dy = second[1] - first[1]
    distance = math.hypot(dx, dy)
    if distance == 0 or distance > radius_first + radius_second:
        return []
    if distance < abs(radius_first - radius_second):
        return []
    along = (radius_first * radius_first - radius_second * radius_second + distance * distance) / (2 * distance)
    height_squared = radius_first * radius_first - along * along
    if height_squared < 0:
        return []
    height = math.sqrt(height_squared)
    base_x = first[0] + along * dx / distance
    base_y = first[1] + along * dy / distance
    return [
        (base_x - height * dy / distance, base_y + height * dx / distance),
        (base_x + height * dy / distance, base_y - height * dx / distance),
    ]


def feasible(ents, limit):
    points = [(ent[0], ent[1]) for ent in ents]
    for first_index in range(len(ents)):
        first = ents[first_index]
        for second_index in range(first_index + 1, len(ents)):
            second = ents[second_index]
            points.extend(circle_crossings(
                (first[0], first[1]), (second[0], second[1]),
                limit * first[2], limit * second[2]))
    tolerance = 1e-12 * max(1.0, abs(limit))
    for point in points:
        if all(math.hypot(point[0] - ent[0], point[1] - ent[1]) <= limit * ent[2] + tolerance
               for ent in ents):
            return True
    return False


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    test_count = tokens[pos]
    pos += 1
    lines = []
    for _ in range(test_count):
        ent_count = tokens[pos]
        pos += 1
        ents = []
        for _ in range(ent_count):
            ents.append((tokens[pos], tokens[pos + 1], tokens[pos + 2]))
            pos += 3
        first_ent = ents[0]
        high = max(math.hypot(first_ent[0] - ent[0], first_ent[1] - ent[1]) / ent[2]
                   for ent in ents)
        low = 0.0
        for _ in range(70):
            middle = (low + high) / 2
            if feasible(ents, middle):
                high = middle
            else:
                low = middle
        lines.append("%.6f" % high)
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n0 0 1\n10 0 1\n").startswith("5.000000")
assert oracle("1\n2\n-5 0 1\n5 0 2\n").startswith("3.33333")
assert oracle("1\n3\n0 0 2\n0 0 3\n0 0 4\n") == "0.000000\n"


def write(name, cases):
    parts = [str(len(cases))]
    for ents in cases:
        parts.append(str(len(ents)))
        for ent in ents:
            parts.append(f"{ent[0]} {ent[1]} {ent[2]}")
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        [(0, 0, 1)],
        [(0, 0, 1), (10, 0, 1)],
        [(-1000000, -1000000, 1), (1000000, 1000000, 1000000)],
    ])
    write("3_wide", [
        [(-1000000, -1000000, 1), (1000000, 1000000, 1), (0, 1000000, 3)],
        [(0, 0, 1000000), (1, 0, 1), (0, 1, 1)],
    ])
    write("4_random", [
        [(rng.randint(-1000, 1000), rng.randint(-1000, 1000), rng.randint(1, 20))
         for _ in range(rng.randint(2, 8))]
        for _ in range(4)
    ])
    write("5_io", [
        [(rng.randint(-100000, 100000), rng.randint(-100000, 100000), rng.randint(1, 100))
         for _ in range(8)]
        for _ in range(10)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
