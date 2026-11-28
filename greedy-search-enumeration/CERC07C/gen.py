#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_scenario(points, radius):
    candidates = list(points)
    radius_squared = radius * radius
    for first in range(len(points)):
        for second in range(first + 1, len(points)):
            delta_x = points[second][0] - points[first][0]
            delta_y = points[second][1] - points[first][1]
            distance_squared = delta_x * delta_x + delta_y * delta_y
            if distance_squared == 0 or distance_squared > 4 * radius_squared:
                continue
            distance = math.sqrt(distance_squared)
            middle_x = (points[first][0] + points[second][0]) / 2.0
            middle_y = (points[first][1] + points[second][1]) / 2.0
            height = math.sqrt(max(0.0, radius_squared - distance_squared / 4.0))
            offset_x = height * delta_y / distance
            offset_y = height * delta_x / distance
            candidates.append((middle_x - offset_x, middle_y + offset_y))
            candidates.append((middle_x + offset_x, middle_y - offset_y))
    limit = (radius + 0.0000001) ** 2
    best = 1
    for center_x, center_y in candidates:
        covered = 0
        for point_x, point_y in points:
            difference_x = point_x - center_x
            difference_y = point_y - center_y
            if difference_x * difference_x + difference_y * difference_y <= limit:
                covered += 1
        if covered > best:
            best = covered
    return best


def parse(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    scenarios = []
    while cursor + 1 < len(tokens):
        count = tokens[cursor]; cursor += 1
        radius = tokens[cursor]; cursor += 1
        if count == 0 and radius == 0:
            break
        points = []
        for _ in range(count):
            points.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        scenarios.append((points, radius))
    return scenarios


def oracle(text):
    answers = []
    for points, radius in parse(text):
        answers.append(f"It is possible to cover {oracle_scenario(points, radius)} points.")
    return "\n".join(answers) + "\n"


SAMPLE = """8 2
1 2
5 3
5 4
1 4
8 2
4 5
7 5
3 3

2 100
0 100
0 -100

0 0
"""
SAMPLE_OUT = """It is possible to cover 4 points.
It is possible to cover 2 points.
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 0\n0 0\n0 0\n") == "It is possible to cover 1 points.\n"
assert oracle("2 5\n0 0\n0 10\n0 0\n") == "It is possible to cover 2 points.\n"
assert oracle("3 1\n0 0\n0 2\n0 4\n0 0\n") == "It is possible to cover 2 points.\n"
assert oracle("4 2\n2 0\n-2 0\n0 2\n0 -2\n0 0\n") == "It is possible to cover 4 points.\n"


def write(name, scenarios):
    chunks = []
    for points, radius in scenarios:
        chunks.append(f"{len(points)} {radius}\n" +
                      "".join(f"{point_x} {point_y}\n" for point_x, point_y in points) + "\n")
    text = "".join(chunks) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([(0, 0)], 0),
        ([(0, 0), (1, 1)], 0),
        ([(0, 0), (0, 10)], 5),
        ([(0, 0), (0, 2), (0, 4)], 1),
        ([(2, 0), (-2, 0), (0, 2), (0, -2)], 2),
        ([(0, 0), (100, 100)], 9999),
    ])
    rng = random.Random(20261129)
    wide_points = [(rng.randint(-9999, 9999), rng.randint(-9999, 9999))
                   for _ in range(60)]
    write("3_wide", [(wide_points, 50)])
    random_scenarios = []
    for _ in range(15):
        count = rng.randint(1, 25)
        points = [(rng.randint(-200, 200), rng.randint(-200, 200))
                  for _ in range(count)]
        random_scenarios.append((points, rng.randint(0, 100)))
    write("4_random", random_scenarios)
    io_scenarios = []
    for index in range(4000):
        io_scenarios.append(([(index % 101 - 50, index % 37 - 18)], index % 50))
    write("5_io", io_scenarios)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
