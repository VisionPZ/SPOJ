#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def doubled_area(points, first, second, third):
    x1, y1 = points[first]
    x2, y2 = points[second]
    x3, y3 = points[third]
    return abs((x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1))


def triangulations(points, left, right):
    if right == left + 1:
        yield ()
        return
    for split in range(left + 1, right):
        for left_part in triangulations(points, left, split):
            for right_part in triangulations(points, split, right):
                yield left_part + right_part + ((left, split, right),)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    scenario_count = tokens[position]
    position += 1
    answers = []
    for _ in range(scenario_count):
        vertex_count = tokens[position]
        position += 1
        points = []
        for _ in range(vertex_count):
            points.append((tokens[position], tokens[position + 1]))
            position += 2
        best = None
        for layout in triangulations(points, 0, vertex_count - 1):
            worst = max(doubled_area(points, *triangle) for triangle in layout)
            if best is None or worst < best:
                best = worst
        answers.append(f"{best // 2}.{5 if best % 2 else 0}")
    return "\n".join(answers) + "\n"


SAMPLE = """1
6
7 0
6 2
9 5
3 5
0 3
1 1
"""
SAMPLE_OUT = """9.0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n0 0\n4 0\n0 4\n") == "8.0\n"
assert oracle("1\n4\n0 0\n10 0\n10 10\n0 10\n") == "50.0\n"
assert oracle("1\n4\n0 0\n8 0\n8 6\n0 6\n") == "24.0\n"
count_five = sum(1 for _ in triangulations(list(range(5)), 0, 4))
assert count_five == 5


def write(name, polygons):
    lines = [str(len(polygons))]
    for points in polygons:
        lines.append(str(len(points)))
        for x_coord, y_coord in points:
            lines.append(f"{x_coord} {y_coord}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def parabola(vertex_count, rng):
    x_positions = sorted(rng.sample(range(0, 1001), vertex_count))
    return [(x_position, (x_position * x_position) // 100) for x_position in x_positions]


def build():
    rng = random.Random(20261126)
    write("2_edges", [[(0, 0), (10, 0), (0, 6)]])
    write("3_wide", [parabola(10, rng)])
    write("4_random", [parabola(8, rng) for _ in range(3)])
    write("5_io", [parabola(9, rng) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
