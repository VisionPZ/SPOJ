#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def circle_from_pair(first, second):
    center = ((first[0] + second[0]) / 2.0, (first[1] + second[1]) / 2.0)
    radius = math.hypot(first[0] - center[0], first[1] - center[1])
    return center, radius


def circle_from_triple(first, second, third):
    ax, ay = first
    bx, by = second
    cx, cy = third
    divisor = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    if abs(divisor) < 1e-9:
        candidates = [circle_from_pair(first, second),
                      circle_from_pair(first, third),
                      circle_from_pair(second, third)]
        return min(candidates, key=lambda item: item[1])
    first_norm = ax * ax + ay * ay
    second_norm = bx * bx + by * by
    third_norm = cx * cx + cy * cy
    center_x = (first_norm * (by - cy) + second_norm * (cy - ay) + third_norm * (ay - by)) / divisor
    center_y = (first_norm * (cx - bx) + second_norm * (ax - cx) + third_norm * (bx - ax)) / divisor
    radius = math.hypot(ax - center_x, ay - center_y)
    return (center_x, center_y), radius


def format_value(value):
    if -0.00005 < value < 0.00005:
        value = 0.0
    return f"{value:.4f}"


def oracle(text):
    numbers = [float(value) for value in text.replace(",", " ").split()]
    cursor = 0
    lines = []
    while cursor < len(numbers):
        count = int(numbers[cursor])
        cursor += 1
        if count == 0:
            break
        points = [(numbers[cursor + 2 * index], numbers[cursor + 2 * index + 1])
                  for index in range(count)]
        cursor += 2 * count
        best = None
        candidates = [(point, 0.0) for point in points]
        for index in range(count):
            for other in range(index + 1, count):
                candidates.append(circle_from_pair(points[index], points[other]))
        for first in range(count):
            for second in range(first + 1, count):
                for third in range(second + 1, count):
                    candidates.append(circle_from_triple(points[first], points[second], points[third]))
        for center, radius in candidates:
            if all((point[0] - center[0]) ** 2 + (point[1] - center[1]) ** 2 <= radius * radius + 1e-7
                   for point in points):
                if best is None or radius < best[1]:
                    best = (center, radius)
        lines.append(format_value(best[0][0]) + ", " + format_value(best[0][1]))
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = """2
-1 0
1 0
4
0.5 0.5
0.5 -0.5
0.0 0.5
0.0 -0.5
0
"""
SAMPLE_OUT = """0.0000, 0.0000
0.2500, 0.0000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 3\n0\n") == "3.0000, 3.0000\n"
assert oracle("2\n0 0\n2 0\n0\n") == "1.0000, 0.0000\n"
assert oracle("3\n0 0\n0 4\n4 0\n0\n") == "2.0000, 2.0000\n"
assert circle_from_pair((0, 0), (2, 0)) == ((1.0, 0.0), 1.0)


def write(name, cases):
    chunks = []
    for points in cases:
        chunks.append(str(len(points)))
        for pos_x, pos_y in points:
            chunks.append(f"{pos_x} {pos_y}")
    text = "\n".join(chunks) + "\n0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[(5, 5)], [(0, 0), (2, 0)], [(0, 0), (0, 4), (4, 0)]])
    ring = [(round(100 * math.cos(2 * math.pi * index / 20), 4),
             round(100 * math.sin(2 * math.pi * index / 20), 4)) for index in range(20)]
    write("3_wide", [ring])
    rng = random.Random(20261126)
    def random_points(count):
        points = set()
        while len(points) < count:
            points.add((rng.randint(-100, 100), rng.randint(-100, 100)))
        return sorted(points)
    write("4_random", [random_points(12) for _ in range(3)])
    write("5_io", [random_points(8) for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
