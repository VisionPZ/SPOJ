#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 100000007


def cross(first, second):
    return first[0] * second[1] - first[1] * second[0]


def subtract(first, second):
    return (first[0] - second[0], first[1] - second[1])


def add(first, second):
    return (first[0] + second[0], first[1] + second[1])


def scale(point, factor):
    return (point[0] * factor, point[1] * factor)


def cyclic_order(points):
    centre = (sum(point[0] for point in points) / 4.0,
              sum(point[1] for point in points) / 4.0)
    return sorted(points, key=lambda point: math.atan2(point[1] - centre[1], point[0] - centre[0]))


def brute_sum(points):
    ordered = cyclic_order(points)
    first, second, third, fourth = ordered
    candidates = [first,
                  subtract(scale(first, 2), second),
                  (first[0] - second[0] + fourth[0], first[1] - second[1] + fourth[1]),
                  fourth]
    xs = [point[0] for point in candidates]
    ys = [point[1] for point in candidates]
    total = 0
    for x in range(min(xs) - 2, max(xs) + 3):
        for y in range(min(ys) - 2, max(ys) + 3):
            vertex_a = (x, y)
            vertex_b = subtract(scale(first, 2), vertex_a)
            vertex_c = subtract(scale(second, 2), vertex_b)
            vertex_d = subtract(scale(third, 2), vertex_c)
            if add(vertex_d, vertex_a) != scale(fourth, 2):
                continue
            vertices = [vertex_a, vertex_b, vertex_c, vertex_d]
            turns = []
            for index in range(4):
                edge_one = subtract(vertices[(index + 1) % 4], vertices[index])
                edge_two = subtract(vertices[(index + 2) % 4], vertices[(index + 1) % 4])
                turns.append(cross(edge_one, edge_two))
            if any(turn == 0 for turn in turns):
                continue
            if not (all(turn > 0 for turn in turns) or all(turn < 0 for turn in turns)):
                continue
            doubled_area = 0
            for index in range(4):
                here = vertices[index]
                following = vertices[(index + 1) % 4]
                doubled_area += here[0] * following[1] - following[0] * here[1]
            total += abs(doubled_area) // 2
    return total % MODULUS


def formula_sum(points):
    distances = []
    for first_index in range(4):
        for second_index in range(first_index + 1, 4):
            delta = subtract(points[second_index], points[first_index])
            distances.append((delta[0] * delta[0] + delta[1] * delta[1],
                              points[first_index], points[second_index]))
    side_squared, base, _ = min(distances, key=lambda item: item[0])
    neighbours = []
    for point in points:
        if point == base:
            continue
        delta = subtract(point, base)
        if delta[0] * delta[0] + delta[1] * delta[1] == side_squared:
            neighbours.append(delta)
    first_steps = math.gcd(abs(neighbours[0][0]), abs(neighbours[0][1]))
    second_steps = math.gcd(abs(neighbours[1][0]), abs(neighbours[1][1]))
    interior = side_squared - first_steps - second_steps + 1
    return (interior % MODULUS) * ((2 * (side_squared % MODULUS)) % MODULUS) % MODULUS


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        points = [(tokens[cursor], tokens[cursor + 1]),
                  (tokens[cursor + 2], tokens[cursor + 3]),
                  (tokens[cursor + 4], tokens[cursor + 5]),
                  (tokens[cursor + 6], tokens[cursor + 7])]
        cursor += 8
        if max(abs(point[0]) for point in points) <= 60 and max(abs(point[1]) for point in points) <= 60:
            answer = brute_sum(points)
        else:
            answer = formula_sum(points)
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


SAMPLE = """2
0 0
1 1
1 0
0 1
0 1
1 0
0 -1
-1 0
"""
SAMPLE_OUT = """0
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_sum([(0, 0), (2, 0), (2, 2), (0, 2)]) == 8
assert formula_sum([(0, 0), (2, 0), (2, 2), (0, 2)]) == 8
assert brute_sum([(0, 1), (1, 0), (0, -1), (-1, 0)]) == 4
assert formula_sum([(0, 1), (1, 0), (0, -1), (-1, 0)]) == 4
assert brute_sum([(0, 0), (3, 0), (3, 3), (0, 3)]) == 72
assert formula_sum([(0, 0), (3, 0), (3, 3), (0, 3)]) == 72


def square(base_x, base_y, side_x, side_y):
    other_x, other_y = -side_y, side_x
    return [(base_x, base_y),
            (base_x + side_x, base_y + side_y),
            (base_x + side_x + other_x, base_y + side_y + other_y),
            (base_x + other_x, base_y + other_y)]


def write(name, cases):
    parts = [str(len(cases))]
    for points in cases:
        parts.extend(f"{point[0]} {point[1]}" for point in points)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [square(0, 0, 1, 0), square(-3, 4, 0, 5),
                      [(0, 1), (1, 0), (0, -1), (-1, 0)]])
    write("3_wide", [square(-1000000000, -1000000000, 1000000000, 0),
                     square(0, 0, 1000000000, 1000000000)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(40):
        base_x = rng.randint(-40, 40)
        base_y = rng.randint(-40, 40)
        side_x = rng.randint(-12, 12)
        side_y = rng.randint(-12, 12)
        if side_x == 0 and side_y == 0:
            side_x = 3
        random_cases.append(square(base_x, base_y, side_x, side_y))
    write("4_random", random_cases)
    io_cases = []
    for index in range(250):
        io_cases.append(square(index - 125, -125, 2 if index % 2 else 7, 0))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
