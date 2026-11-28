#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def cross(first, second, third):
    return ((second[0] - first[0]) * (third[1] - first[1])
            - (second[1] - first[1]) * (third[0] - first[0]))


def hull(subset):
    ordered = sorted(subset)
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


def doubled_area(points):
    total = 0
    for index in range(len(points)):
        first = points[index]
        second = points[(index + 1) % len(points)]
        total += first[0] * second[1] - second[0] * first[1]
    return abs(total)


def oracle(point_count, vertex_count, points):
    best = None
    for subset in itertools.combinations(points, vertex_count):
        outline = hull(subset)
        if len(outline) != vertex_count:
            continue
        area = doubled_area(outline)
        if best is None or area < best:
            best = area
    return str(0 if best is None else best // 2) + "\n"


def encode(point_count, vertex_count, points):
    lines = [f"{point_count} {vertex_count}"]
    lines.extend(f"{x} {y}" for x, y in points)
    return "\n".join(lines) + "\n"


SAMPLE = [(0, 0), (1, 1), (0, 10), (10, 0)]
assert oracle(4, 3, SAMPLE) == "5\n"
assert encode(4, 3, SAMPLE) == "4 3\n0 0\n1 1\n0 10\n10 0\n"
assert oracle(3, 3, [(0, 0), (1, 1), (2, 0)]) == "1\n"
assert oracle(4, 4, [(0, 0), (3, 0), (3, 3), (0, 3)]) == "9\n"
assert oracle(4, 4, [(0, 0), (2, 0), (2, 2), (0, 2)]) == "4\n"
assert oracle(3, 4, [(0, 0), (1, 1), (2, 0)]) == "0\n"


def write(name, vertex_count, points):
    text = encode(len(points), vertex_count, points)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(len(points), vertex_count, points))


def random_points(rng, count):
    points = []
    while len(points) < count:
        candidate = (rng.randint(0, 40), rng.randint(0, 40))
        if candidate in points:
            continue
        if any(cross(points[a], points[b], candidate) == 0
               for a in range(len(points)) for b in range(a + 1, len(points))):
            continue
        points.append(candidate)
    return points


def build():
    rng = random.Random(20261126)
    write("2_edges", 3, [(0, 0), (1, 5), (9, 0)])
    write("3_wide", 9, random_points(rng, 9))
    write("4_random", 10, random_points(rng, 10))
    write("5_io", 10, random_points(rng, 10))
    big_points = random_points(rng, 49)
    Path("/tmp/POLYSSQ_big.txt").write_text(encode(49, 10, big_points))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, SAMPLE)
build()
