#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def cross(origin, first, second):
    return (first[0] - origin[0]) * (second[1] - origin[1]) - \
           (first[1] - origin[1]) * (second[0] - origin[0])


def distance_squared(first, second):
    return (first[0] - second[0]) ** 2 + (first[1] - second[1]) ** 2


def point_segment_distance(point, first, second):
    dx = second[0] - first[0]
    dy = second[1] - first[1]
    length_squared = dx * dx + dy * dy
    if length_squared == 0:
        return math.hypot(point[0] - first[0], point[1] - first[1])
    parameter = ((point[0] - first[0]) * dx + (point[1] - first[1]) * dy) / length_squared
    parameter = max(0.0, min(1.0, parameter))
    nearest_x = first[0] + parameter * dx
    nearest_y = first[1] + parameter * dy
    return math.hypot(point[0] - nearest_x, point[1] - nearest_y)


def jarvis_march(points):
    count = len(points)
    if count < 3:
        return points
    start = min(range(count), key=lambda index: (points[index][1], points[index][0]))
    hull = []
    current = start
    while True:
        hull.append(points[current])
        candidate = (current + 1) % count
        for trial in range(count):
            if trial == current:
                continue
            turn = cross(points[current], points[candidate], points[trial])
            if turn > 0 or (turn == 0 and
                            distance_squared(points[current], points[trial]) >
                            distance_squared(points[current], points[candidate])):
                candidate = trial
        current = candidate
        if current == start:
            break
    return hull


def oracle_case(points, radius):
    count = len(points)
    for first in range(count):
        for second in range(first + 1, count):
            for third in range(count):
                if third == first or third == second:
                    continue
                if point_segment_distance(points[third], points[first],
                                          points[second]) < radius - 1e-9:
                    return "NO CONTEST"
    hull = jarvis_march(points)
    doubled_area = abs(sum(hull[i][0] * hull[(i + 1) % len(hull)][1] -
                           hull[(i + 1) % len(hull)][0] * hull[i][1]
                           for i in range(len(hull))))
    return f"{doubled_area / 2:.2f}"


def oracle(text):
    tokens = [int(token) for token in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        antenna_count = tokens[cursor]
        radius = tokens[cursor + 1]
        cursor += 2
        points = [(0, 0)]
        for _ in range(antenna_count - 1):
            points.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        answers.append(oracle_case(points, radius))
    return "\n".join(answers) + "\n"


SAMPLE = """2
4 1
2 0
2 2
0 2
5 1
2 0
2 2
0 2
1 1
"""
SAMPLE_OUT = """4.00
NO CONTEST
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 1\n100 0\n0 100\n") == "5000.00\n"
assert oracle("1\n3 1\n0 0\n0 1\n") == "NO CONTEST\n"
assert oracle("1\n3 7\n10 0\n0 10\n") == "50.00\n"
assert len(jarvis_march([(0, 0), (2, 0), (2, 2), (0, 2)])) == 4


def case_text(points, radius):
    text = f"{len(points)} {radius}\n"
    for point_x, point_y in points[1:]:
        text += f"{point_x} {point_y}\n"
    return text


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, count, radius):
    points = [(0, 0)]
    for _ in range(count - 1):
        points.append((rng.randint(-500, 500), rng.randint(-500, 500)))
    return points, radius


def build():
    write("2_edges", [([(0, 0), (0, 10), (0, 20)], 1),
                      ([(0, 0), (100, -100), (-100, 100)], 5)])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 100, 1)])
    write("4_random", [random_case(rng, rng.randint(3, 12), rng.randint(1, 10))
                       for _ in range(10)])
    write("5_io", [random_case(rng, 20, rng.randint(1, 5)) for _ in range(100)])
    big_rng = random.Random(27182)
    with open("/tmp/VPL1_AC_big.txt", "w") as handle:
        handle.write("100\n")
        for _ in range(100):
            points, radius = random_case(big_rng, 100, 3)
            handle.write(case_text(points, radius))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([(0, 0), (2, 0), (2, 2), (0, 2)], 1),
                   ([(0, 0), (2, 0), (2, 2), (0, 2), (1, 1)], 1)])
build()
