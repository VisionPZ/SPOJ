#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def forward_coefficients(result_coefficients):
    degree = len(result_coefficients) - 1
    source = [0] * (degree + 1)
    for higher_degree in range(degree + 1):
        for lower_degree in range(higher_degree + 1):
            sign = 1 if (higher_degree - lower_degree) % 2 == 0 else -1
            source[lower_degree] += (sign * result_coefficients[higher_degree] *
                                     math.comb(higher_degree + 1, lower_degree))
    return source


def evaluate(coefficients, point):
    value = 0
    for coefficient in reversed(coefficients):
        value = value * point + coefficient
    return value


def interpolate(points):
    count = len(points)
    result = [Fraction(0) for _ in range(count)]
    for base_index in range(count):
        base_x, base_y = points[base_index]
        basis = [Fraction(1)]
        denominator = Fraction(1)
        for other_index in range(count):
            if other_index == base_index:
                continue
            other_x, _ = points[other_index]
            shifted = [Fraction(0)] + basis
            for position in range(len(basis)):
                shifted[position] -= basis[position] * other_x
            basis = shifted
            denominator *= Fraction(base_x - other_x)
        scale = Fraction(base_y) / denominator
        for position in range(count):
            result[position] += basis[position] * scale
    return result


def oracle_case(coefficients):
    degree = len(coefficients) - 1
    points = []
    running = 0
    for point in range(1, degree + 2):
        running += evaluate(coefficients, point)
        points.append((point, Fraction(running, point)))
    return interpolate(points)


def oracle(cases):
    lines = []
    for coefficients in cases:
        answer = oracle_case(coefficients)
        assert all(value.denominator == 1 for value in answer)
        lines.append(" ".join(str(value.numerator) for value in answer))
    return "\n".join(lines) + "\n"


SAMPLE_CASES = [[13], [-1, 2], [0, 2], [2, -5, 9], [23, 9, 21, 104]]
SAMPLE = "5\n0\n13\n1\n-1 2\n1\n0 2\n2\n2 -5 9\n3\n23 9 21 104\n"
SAMPLE_OUT = "13\n0 1\n1 1\n1 2 3\n31 41 59 26\n"
assert oracle(SAMPLE_CASES) == SAMPLE_OUT
assert oracle([[13]]) == "13\n"
assert oracle([[-1, 2]]) == "0 1\n"
assert oracle([[0, 2]]) == "1 1\n"
assert oracle([[2, -5, 9]]) == "1 2 3\n"
assert oracle([[23, 9, 21, 104]]) == "31 41 59 26\n"
for degree in range(0, 6):
    expected = [((index * 7) % 11) - 5 for index in range(degree + 1)]
    assert oracle_case(forward_coefficients(expected)) == [Fraction(value) for value in expected]


def write(name, cases):
    parts = [str(len(cases))]
    for coefficients in cases:
        parts.append(str(len(coefficients) - 1))
        parts.append(" ".join(str(value) for value in coefficients))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def build():
    rng = random.Random(20261126)

    def random_case(degree):
        answer = [rng.randint(-9, 9) for _ in range(degree + 1)]
        answer[-1] = rng.choice([value for value in range(-9, 10) if value != 0])
        return forward_coefficients(answer)

    write("2_edges", [[13], [-1, 2], [0, 2],
                      forward_coefficients([3, 3]),
                      forward_coefficients([1, -2, 4])])
    write("3_wide", [random_case(18) for _ in range(40)])
    write("4_random", [random_case(rng.randint(0, 18)) for _ in range(200)])
    write("5_io", [random_case(rng.randint(0, 4)) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
