#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLES = 200


def sub(left, right):
    return (left[0] - right[0], left[1] - right[1], left[2] - right[2])


def add(left, right):
    return (left[0] + right[0], left[1] + right[1], left[2] + right[2])


def scale(value, factor):
    return (value[0] * factor, value[1] * factor, value[2] * factor)


def dot(left, right):
    return left[0] * right[0] + left[1] * right[1] + left[2] * right[2]


def cross(left, right):
    return (left[1] * right[2] - left[2] * right[1],
            left[2] * right[0] - left[0] * right[2],
            left[0] * right[1] - left[1] * right[0])


def norm2(value):
    return dot(value, value)


def circle_parameters(points):
    first, second, third = points
    edge_one = sub(second, first)
    edge_two = sub(third, first)
    plane_normal = cross(edge_one, edge_two)
    centre = add(first, scale(add(scale(cross(edge_two, plane_normal), norm2(edge_one)),
                                  scale(cross(plane_normal, edge_one), norm2(edge_two))),
                              1.0 / (2.0 * norm2(plane_normal))))
    radius = math.sqrt(norm2(sub(centre, first)))
    normal = scale(plane_normal, 1.0 / math.sqrt(norm2(plane_normal)))
    return centre, radius, normal


def plane_basis(normal):
    helper = (1.0, 0.0, 0.0) if abs(normal[0]) < 0.9 else (0.0, 1.0, 0.0)
    first_axis = sub(helper, scale(normal, dot(helper, normal)))
    first_axis = scale(first_axis, 1.0 / math.sqrt(norm2(first_axis)))
    return first_axis, cross(normal, first_axis)


def linking_integral(first_points, second_points):
    first_centre, first_radius, first_normal = circle_parameters(first_points)
    second_centre, second_radius, second_normal = circle_parameters(second_points)
    axis_one_first, axis_two_first = plane_basis(first_normal)
    axis_one_second, axis_two_second = plane_basis(second_normal)
    first_samples = []
    first_derivatives = []
    second_samples = []
    second_derivatives = []
    for sample_index in range(SAMPLES):
        angle = 2.0 * math.pi * (sample_index + 0.5) / SAMPLES
        cosine = math.cos(angle)
        sine = math.sin(angle)
        first_samples.append(add(first_centre, add(scale(axis_one_first, first_radius * cosine),
                                                    scale(axis_two_first, first_radius * sine))))
        first_derivatives.append(add(scale(axis_one_first, -first_radius * sine),
                                     scale(axis_two_first, first_radius * cosine)))
        second_samples.append(add(second_centre, add(scale(axis_one_second, second_radius * cosine),
                                                      scale(axis_two_second, second_radius * sine))))
        second_derivatives.append(add(scale(axis_one_second, -second_radius * sine),
                                       scale(axis_two_second, second_radius * cosine)))
    accumulated = 0.0
    for first_point, first_derivative in zip(first_samples, first_derivatives):
        for second_point, second_derivative in zip(second_samples, second_derivatives):
            separation = sub(first_point, second_point)
            distance = math.sqrt(norm2(separation))
            accumulated += dot(separation, cross(first_derivative, second_derivative)) / (distance ** 3)
    step = 2.0 * math.pi / SAMPLES
    return accumulated * step * step / (4.0 * math.pi)


def oracle(cases):
    lines = []
    for first_circle, second_circle in cases:
        if abs(linking_integral(first_circle, second_circle)) > 0.5:
            lines.append("YES")
        else:
            lines.append("NO")
    return "\n".join(lines) + "\n"


SAMPLE_FIRST = [(0, 1, 0), (1, 0, 0), (0, -1, 0)]
SAMPLE_SECOND = [(0, 0, 0), (1, 0, -1), (1, 0, 1)]
SAMPLE = ["1", "0 1 0 1 0 0 0 -1 0", "0 0 0 1 0 -1 1 0 1"]
SAMPLE_TEXT = "\n".join(SAMPLE) + "\n"
SAMPLE_OUT = "YES\n"
assert oracle([(SAMPLE_FIRST, SAMPLE_SECOND)]) == SAMPLE_OUT
assert abs(linking_integral(SAMPLE_FIRST, SAMPLE_SECOND) - 1.0) < 1e-6
assert oracle([([(0, 5, 0), (5, 0, 0), (0, -5, 0)],
                [(0, 0, 0), (5, 0, -5), (5, 0, 5)])]) == "YES\n"
assert oracle([([(5, 0, 0), (0, 5, 0), (-5, 0, 0)],
                [(15, 0, 0), (0, 15, 0), (-15, 0, 0)])]) == "NO\n"
assert oracle([([(0, 5, 0), (5, 0, 0), (0, -5, 0)],
                [(50, 50, 50), (55, 50, 50), (50, 45, 50)])]) == "NO\n"


def linked_pair(size):
    first = [(0, size, 0), (size, 0, 0), (0, -size, 0)]
    second = [(0, 0, 0), (size, 0, -size), (size, 0, size)]
    return first, second


def nested_pair(size):
    first = [(size, 0, 0), (0, size, 0), (-size, 0, 0)]
    second = [(3 * size, 0, 0), (0, 3 * size, 0), (-3 * size, 0, 0)]
    return first, second


def apart_pair(size):
    first, second = nested_pair(size)
    moved = [(point[0] + 6 * size, point[1] + 6 * size, point[2] + 6 * size) for point in second]
    return first, moved


def transform(case, permutation, offset):
    result = []
    for circle in case:
        result.append([tuple(point[permutation[axis]] + offset[axis] for axis in range(3))
                       for point in circle])
    return result[0], result[1]


def write(name, cases):
    blocks = [str(len(cases))]
    for first_circle, second_circle in cases:
        for point in first_circle + second_circle:
            blocks.append(" ".join(str(value) for value in point))
    text = "\n".join(blocks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def build():
    rng = random.Random(20261126)
    permutations = [(0, 1, 2), (1, 2, 0), (2, 0, 1)]
    write("2_edges", [nested_pair(3), apart_pair(4), linked_pair(2)])
    write("3_wide", [transform(linked_pair(1000), (1, 2, 0), (1000, -1000, 500)),
                     transform(nested_pair(1200), (2, 0, 1), (-1000, 500, 1000))])
    random_cases = []
    for case_index in range(12):
        size = rng.randint(10, 200)
        offset = (rng.randint(-500, 500), rng.randint(-500, 500), rng.randint(-500, 500))
        base = rng.choice([linked_pair(size), nested_pair(size), apart_pair(size)])
        random_cases.append(transform(base, rng.choice(permutations), offset))
    write("4_random", random_cases)
    io_cases = []
    for case_index in range(100):
        size = rng.randint(2, 100)
        offset = (rng.randint(-1000, 1000), rng.randint(-1000, 1000), rng.randint(-1000, 1000))
        base = rng.choice([linked_pair(size), nested_pair(size), apart_pair(size)])
        io_cases.append(transform(base, rng.choice(permutations), offset))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_TEXT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
