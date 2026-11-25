#!/usr/bin/env python3
import random
from math import gcd
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(token) for token in text.split()]
    line_count = tokens[0]
    coefficients = []
    for index in range(line_count):
        first_x, first_y, second_x, second_y = tokens[1 + 4 * index:5 + 4 * index]
        direction_x = second_x - first_x
        direction_y = second_y - first_y
        coefficients.append((direction_y, -direction_x, direction_x * first_y - direction_y * first_x))
    pair_counts = {}
    for first_line in range(line_count):
        first_a, first_b, first_c = coefficients[first_line]
        for second_line in range(first_line + 1, line_count):
            second_a, second_b, second_c = coefficients[second_line]
            determinant = first_a * second_b - second_a * first_b
            if determinant == 0:
                continue
            x_numerator = first_b * second_c - second_b * first_c
            y_numerator = first_c * second_a - second_c * first_a
            if determinant < 0:
                determinant = -determinant
                x_numerator = -x_numerator
                y_numerator = -y_numerator
            x_divisor = gcd(abs(x_numerator), determinant)
            y_divisor = gcd(abs(y_numerator), determinant)
            point = (
                x_numerator // x_divisor,
                determinant // x_divisor,
                y_numerator // y_divisor,
                determinant // y_divisor,
            )
            pair_counts[point] = pair_counts.get(point, 0) + 1
    extra_regions = 0
    for pair_total in pair_counts.values():
        lines_through_point = 2
        while lines_through_point * (lines_through_point - 1) // 2 != pair_total:
            lines_through_point += 1
        extra_regions += lines_through_point - 1
    return str(1 + line_count + extra_regions) + "\n"


SAMPLE = """4
5 0 0 5
4 0 4 5
2 4 3 4
1 1 1 5
"""
SAMPLE_OUT = """9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0 1 1\n") == "2\n"
assert oracle("2\n0 0 1 1\n0 1 1 2\n") == "3\n"
assert oracle("2\n0 0 1 0\n0 0 0 1\n") == "4\n"
assert oracle("3\n0 0 1 0\n0 0 0 1\n0 0 1 1\n") == "6\n"


def write(name, lines):
    text = str(len(lines)) + "\n" + "".join(
        f"{first_x} {first_y} {second_x} {second_y}\n"
        for first_x, first_y, second_x, second_y in lines
    )
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (0, 0, 1, 1),
        (0, 0, 1, 0),
        (0, 0, 0, 1),
        (0, 0, 1, -1),
        (5, 5, 6, 7),
        (-3, -4, -5, -7),
        (10000, -10000, 9999, 10000),
    ])
    rng = random.Random(20261126)

    def random_lines(count):
        result = []
        while len(result) < count:
            first_x = rng.randint(-10000, 10000)
            first_y = rng.randint(-10000, 10000)
            second_x = rng.randint(-10000, 10000)
            second_y = rng.randint(-10000, 10000)
            if (first_x, first_y) != (second_x, second_y):
                result.append((first_x, first_y, second_x, second_y))
        return result

    write("3_wide", random_lines(300))
    write("4_random", random_lines(180))
    write("5_io", random_lines(400))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (5, 0, 0, 5),
    (4, 0, 4, 5),
    (2, 4, 3, 4),
    (1, 1, 1, 5),
])
build()
