#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(points):
    best = 0
    for first in range(len(points)):
        for second in range(first + 1, len(points)):
            for third in range(second + 1, len(points)):
                ax, ay = points[first]
                bx, by = points[second]
                cx, cy = points[third]
                doubled = abs((bx - ax) * (cy - ay) - (by - ay) * (cx - ax))
                if doubled > best:
                    best = doubled
    return f"{best // 2}.{'00' if best % 2 == 0 else '50'}\n"


SAMPLE = """3
3 4
2 6
2 7
5
2 6
3 9
2 0
8 0
6 5
-1
"""
SAMPLE_OUT = "0.50\n27.00\n"
assert oracle([(3, 4), (2, 6), (2, 7)]) == "0.50\n"
assert oracle([(2, 6), (3, 9), (2, 0), (8, 0), (6, 5)]) == "27.00\n"
assert oracle([(0, 0), (4, 0), (0, 4)]) == "8.00\n"
assert oracle([(0, 0), (3, 0), (0, 2)]) == "3.00\n"


def write(name, cases):
    chunks = []
    expected = []
    for points in cases:
        chunks.append(str(len(points)) + "\n")
        chunks.append("".join(f"{x} {y}\n" for x, y in points))
        expected.append(oracle(points))
    text = "".join(chunks) + "-1\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("".join(expected))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)

edge_points = [
    [(0, 0), (1, 0), (0, 1)],
    [(-10000, -10000), (10000, -10000), (0, 10000)],
    [(0, 0), (2, 0), (0, 1), (2, 1)],
    [(1, 2), (3, 5), (7, 11), (13, 17), (19, 23)],
]
write("2_edges", edge_points)

rng = random.Random(20261201)
wide_points = []
for _ in range(4):
    points = []
    while len(points) < 35:
        candidate = (rng.randint(-10000, 10000), rng.randint(-10000, 10000))
        if candidate not in points:
            points.append(candidate)
    wide_points.append(points)
write("3_wide", wide_points)

random_points = []
for _ in range(40):
    points = []
    size = rng.randint(3, 12)
    while len(points) < size:
        candidate = (rng.randint(-1000, 1000), rng.randint(-1000, 1000))
        if candidate not in points:
            points.append(candidate)
    random_points.append(points)
write("4_random", random_points)

io_points = []
for _ in range(150):
    points = []
    while len(points) < 20:
        candidate = (rng.randint(-10000, 10000), rng.randint(-10000, 10000))
        if candidate not in points:
            points.append(candidate)
    io_points.append(points)
write("5_io", io_points)
