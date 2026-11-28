#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def hull(points):
    ordered = sorted(set(points))

    def cross(first, second, third):
        return ((second[0] - first[0]) * (third[1] - first[1]) -
                (second[1] - first[1]) * (third[0] - first[0]))

    lower = []
    for point in ordered:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper = []
    for point in reversed(ordered):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    return lower[:-1] + upper[:-1]


def intersect(normal_one, bound_one, normal_two, bound_two):
    determinant = normal_one[0] * normal_two[1] - normal_one[1] * normal_two[0]
    return ((bound_one * normal_two[1] - normal_one[1] * bound_two) / determinant,
            (normal_one[0] * bound_two - bound_one * normal_two[0]) / determinant)


def parallelogram_area(points):
    vertices = hull(points)
    if len(vertices) < 3:
        return 0.0
    normals = []
    for index in range(len(vertices)):
        first_point = vertices[index]
        second_point = vertices[(index + 1) % len(vertices)]
        normals.append((-(second_point[1] - first_point[1]),
                        second_point[0] - first_point[0]))
    best = float("inf")
    for first_index, normal_one in enumerate(normals):
        projections_one = [x * normal_one[0] + y * normal_one[1] for x, y in vertices]
        low_one = min(projections_one)
        high_one = max(projections_one)
        for second_index in range(first_index + 1, len(normals)):
            normal_two = normals[second_index]
            determinant = normal_one[0] * normal_two[1] - normal_one[1] * normal_two[0]
            if determinant == 0:
                continue
            projections_two = [x * normal_two[0] + y * normal_two[1] for x, y in vertices]
            low_two = min(projections_two)
            high_two = max(projections_two)
            corners = [intersect(normal_one, high_one, normal_two, high_two),
                       intersect(normal_one, high_one, normal_two, low_two),
                       intersect(normal_one, low_one, normal_two, low_two),
                       intersect(normal_one, low_one, normal_two, high_two)]
            doubled_area = sum(corners[step][0] * corners[(step + 1) % 4][1] -
                               corners[step][1] * corners[(step + 1) % 4][0]
                               for step in range(4))
            area = abs(doubled_area) / 2
            if area < best:
                best = area
    return best


def dense_scan(points):
    vertices = hull(points)
    if len(vertices) < 3:
        return 0.0
    best = float("inf")
    steps = 400
    widths = []
    for index in range(steps):
        angle = math.pi * index / steps
        normal = (math.cos(angle), math.sin(angle))
        projections = [x * normal[0] + y * normal[1] for x, y in vertices]
        widths.append(max(projections) - min(projections))
    for first in range(steps):
        for second in range(first + 1, steps):
            determinant = abs(math.sin(math.pi * (second - first) / steps))
            if determinant < 1e-9:
                continue
            area = widths[first] * widths[second] / determinant
            if area < best:
                best = area
    return best


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    cursor = 0
    swarm_count = int(lines[cursor])
    cursor += 1
    answers = []
    for swarm_index in range(1, swarm_count + 1):
        ant_count = int(lines[cursor])
        cursor += 1
        points = []
        for _ in range(ant_count):
            point = tuple(float(value) for value in lines[cursor].split())
            points.append(point)
            cursor += 1
        area = parallelogram_area(points)
        answers.append(f"Swarm {swarm_index} Parallelogram Area: {area:.4f}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
6
0.0000 0.0000
-0.5000 -0.5000
-1.0000 0.0000
-0.7000 -7.0000
-1.0000 -1.0000
0.0000 -1.0000
5
2.0000 2.0000
0.0000 0.0000
0.5000 2.0000
1.0000 1.0000
1.5000 0.0000
"""
SAMPLE_OUT = """Swarm 1 Parallelogram Area: 7.0000
Swarm 2 Parallelogram Area: 3.0000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert parallelogram_area([(0, 0), (1, 0), (0, 1), (1, 1)]) == 1.0
assert parallelogram_area([(0, 0), (2, 0), (0, 3), (2, 3)]) == 6.0
assert parallelogram_area([(0, 0), (1, 0), (0, 1)]) == 1.0
rng = random.Random(11)
for _ in range(6):
    sample_points = [(rng.randint(-9, 9), rng.randint(-9, 9)) for _ in range(10)]
    assert parallelogram_area(sample_points) <= dense_scan(sample_points) + 1e-6


def write(name, swarms):
    lines = [str(len(swarms))]
    for points in swarms:
        lines.append(str(len(points)))
        lines.extend(f"{x:.4f} {y:.4f}" for x, y in points)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)

    def swarm(count, low, high):
        points = set()
        while len(points) < count:
            points.add((rng.randint(low, high) / 2, rng.randint(low, high) / 2))
        return sorted(points)

    write("2_edges", [[(0, 0), (1, 0), (0, 1), (1, 1)],
                      [(0, 0), (2, 0), (0, 3), (2, 3)],
                      [(-1, -1), (1, -1), (0, 1), (2, 2)]])
    write("3_wide", [swarm(20, -1000, 1000) for _ in range(4)])
    write("4_random", [swarm(rng.randint(6, 24), -50, 50) for _ in range(12)])
    write("5_io", [swarm(12, -30, 30) for _ in range(60)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
