#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    rectangle_count = int(tokens[cursor]); cursor += 1
    point_count = int(tokens[cursor]); cursor += 1
    rectangles = []
    for _ in range(rectangle_count):
        first_x = int(tokens[cursor]); cursor += 1
        first_y = int(tokens[cursor]); cursor += 1
        second_x = int(tokens[cursor]); cursor += 1
        second_y = int(tokens[cursor]); cursor += 1
        rectangles.append((min(first_x, second_x), max(first_x, second_x),
                           min(first_y, second_y), max(first_y, second_y)))
    covered = 0
    for _ in range(point_count):
        point_x = int(tokens[cursor]); cursor += 1
        point_y = int(tokens[cursor]); cursor += 1
        if any(x_low <= point_x <= x_high and y_low <= point_y <= y_high
               for x_low, x_high, y_low, y_high in rectangles):
            covered += 1
    return str(covered) + "\n"


SAMPLE = """5 10
-1 -1 2 5
4 -3 5 3
1 2 4 4
5 -6 8 -4
1 -2 8 0
1 4
5 4
2 2
3 1
6 -5
5 -1
3 -3
-1 -2
-1 -1
2 -1
"""
SAMPLE_OUT = "6\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0 0 0 0\n0 0\n") == "1\n"
assert oracle("1 2\n0 0 2 2\n0 0\n2 2\n") == "2\n"
assert oracle("2 3\n0 0 0 0\n2 2 2 2\n0 0\n1 1\n2 2\n") == "2\n"
assert oracle("1 4\n-1 -1 1 1\n-1 -1\n1 1\n2 2\n0 0\n") == "3\n"


def write(name, rectangles, points):
    lines = [f"{len(rectangles)} {len(points)}"]
    lines.extend(" ".join(str(value) for value in rect) for rect in rectangles)
    lines.extend(f"{point_x} {point_y}" for point_x, point_y in points)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges",
          [(0, 0, 0, 0), (2, 4, 3, 3), (-1, 1, 0, 0), (1000000000, 1000000000,
                                                        -1000000000, 1000000000)],
          [(0, 0), (0, 2), (1, 3), (2, 3), (4, 3), (5, 3), (0, 0),
           (1000000000, 0), (1000000000, 1000000000)])
    rng = random.Random(20261126)
    rectangles = [(rng.randint(-10**9, 10**9), rng.randint(-10**9, 10**9),
                   rng.randint(-10**9, 10**9), rng.randint(-10**9, 10**9))
                  for _ in range(40)]
    points = [(rng.randint(-10**9, 10**9), rng.randint(-10**9, 10**9))
              for _ in range(40)]
    write("3_wide", rectangles, points)
    rectangles = []
    points = []
    for _ in range(60):
        low_x = rng.randint(-100, 100)
        low_y = rng.randint(-100, 100)
        rectangles.append((low_x, low_x + rng.randint(0, 60),
                           low_y, low_y + rng.randint(0, 60)))
    for _ in range(60):
        points.append((rng.randint(-120, 180), rng.randint(-120, 180)))
    write("4_random", rectangles, points)
    rectangles = [(index - 150, index + 150, index - 150, index + 150)
                  for index in range(300)]
    points = [(0, 0) for _ in range(300)]
    write("5_io", rectangles, points)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample",
      [(-1, -1, 2, 5), (4, -3, 5, 3), (1, 2, 4, 4), (5, -6, 8, -4),
       (1, -2, 8, 0)],
      [(1, 4), (5, 4), (2, 2), (3, 1), (6, -5), (5, -1), (3, -3),
       (-1, -2), (-1, -1), (2, -1)])
build()
