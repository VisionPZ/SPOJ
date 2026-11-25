#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def side(edge_start, edge_end, point):
    delta_x = edge_end[0] - edge_start[0]
    delta_y = edge_end[1] - edge_start[1]
    return delta_x * (point[1] - edge_start[1]) - delta_y * (point[0] - edge_start[0])


def clip_halfplane(polygon, edge_start, edge_end):
    result = []
    for index in range(len(polygon)):
        current = polygon[index]
        following = polygon[(index + 1) % len(polygon)]
        current_side = side(edge_start, edge_end, current)
        following_side = side(edge_start, edge_end, following)
        if current_side >= 0:
            result.append(current)
        if (current_side > 0 and following_side < 0) or (current_side < 0 and following_side > 0):
            ratio = Fraction(current_side, current_side - following_side)
            crossing = (current[0] + ratio * (following[0] - current[0]),
                        current[1] + ratio * (following[1] - current[1]))
            result.append(crossing)
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while True:
        vertex_count = tokens[cursor]
        cursor += 1
        if vertex_count == 0:
            break
        vertices = []
        for _ in range(vertex_count):
            vertices.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        region = [(Fraction(-1000000), Fraction(-1000000)),
                  (Fraction(1000000), Fraction(-1000000)),
                  (Fraction(1000000), Fraction(1000000)),
                  (Fraction(-1000000), Fraction(1000000))]
        for index in range(vertex_count):
            region = clip_halfplane(region, vertices[index], vertices[(index + 1) % vertex_count])
            if not region:
                break
        answers.append("1" if region else "0")
    return "\n".join(answers) + "\n"


SAMPLE = """6
66 13
96 61
76 98
13 94
4 0
45 68
8
27 21
55 14
93 12
56 95
15 48
38 46
51 65
64 31
0
"""
SAMPLE_OUT = """1
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("4\n0 0\n10 0\n10 10\n0 10\n0\n") == "1\n"
assert oracle("8\n0 0\n10 0\n10 10\n6 10\n6 2\n4 2\n4 10\n0 10\n0\n") == "0\n"
assert clip_halfplane([(Fraction(0), Fraction(0)), (Fraction(2), Fraction(0)),
                       (Fraction(2), Fraction(2)), (Fraction(0), Fraction(2))],
                      (0, 0), (2, 0)) == [(Fraction(0), Fraction(0)), (Fraction(2), Fraction(0)),
                                          (Fraction(2), Fraction(2)), (Fraction(0), Fraction(2))]


def render(polygons):
    lines = []
    for vertices in polygons:
        lines.append(str(len(vertices)))
        for pos_x, pos_y in vertices:
            lines.append(f"{pos_x} {pos_y}")
    lines.append("0")
    return "\n".join(lines) + "\n"


def write(name, polygons):
    text = render(polygons)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def radial_polygon(rng, vertex_count):
    angles = [2 * math.pi * (index + rng.uniform(-0.3, 0.3)) / vertex_count
              for index in range(vertex_count)]
    radii = [rng.randint(800, 4000) for _ in range(vertex_count)]
    vertices = []
    for angle, radius in zip(angles, radii):
        pos_x = int(round(5000 + radius * math.cos(angle)))
        pos_y = int(round(5000 + radius * math.sin(angle)))
        vertices.append((min(max(pos_x, 0), 10000), min(max(pos_y, 0), 10000)))
    return vertices


def u_polygon(rng):
    scale = rng.randint(200, 900)
    offset_x = rng.randint(0, 10000 - 10 * scale)
    offset_y = rng.randint(0, 10000 - 10 * scale)
    base = [(0, 0), (10, 0), (10, 10), (6, 10), (6, 2), (4, 2), (4, 10), (0, 10)]
    return [(offset_x + pos_x * scale, offset_y + pos_y * scale) for pos_x, pos_y in base]


def build():
    square = [(0, 0), (10, 0), (10, 10), (0, 10)]
    notch = [(0, 0), (10, 0), (6, 1), (10, 10), (0, 10)]
    write("2_edges", [square, notch, [(0, 0), (8, 0), (3, 1), (8, 8), (0, 8)]])
    rng = random.Random(20261126)
    write("3_wide", [radial_polygon(rng, 50), u_polygon(rng)])
    polygons = []
    for _ in range(12):
        if rng.random() < 0.5:
            polygons.append(radial_polygon(rng, rng.randint(4, 50)))
        else:
            polygons.append(u_polygon(rng))
    write("4_random", polygons)
    write("5_io", [radial_polygon(rng, rng.randint(4, 16)) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
