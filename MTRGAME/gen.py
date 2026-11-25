#!/usr/bin/env python3
import random
from fractions import Fraction
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def linear_solve(coefficients, right_sides):
    size = len(right_sides)
    rows = [list(row) for row in coefficients]
    values = list(right_sides)
    for column in range(size):
        pivot = None
        for index in range(column, size):
            if rows[index][column] != 0:
                pivot = index
                break
        if pivot is None:
            return None
        rows[column], rows[pivot] = rows[pivot], rows[column]
        values[column], values[pivot] = values[pivot], values[column]
        divisor = rows[column][column]
        rows[column] = [value / divisor for value in rows[column]]
        values[column] /= divisor
        for index in range(size):
            if index == column or rows[index][column] == 0:
                continue
            factor = rows[index][column]
            rows[index] = [rows[index][position] - factor * rows[column][position]
                           for position in range(size)]
            values[index] -= factor * values[column]
    return values


def format_value(value):
    scaled = abs(value) * 1000
    rounded = (scaled.numerator * 2 + scaled.denominator) // (2 * scaled.denominator)
    sign = "-" if value < 0 else ""
    whole = rounded // 1000
    fraction = rounded % 1000
    return f"{sign}{whole}.{fraction // 100}{(fraction // 10) % 10}{fraction % 10}"


def oracle_case(matrix):
    row_count = len(matrix)
    column_count = len(matrix[0])
    if row_count == 1:
        return min(Fraction(value) for value in matrix[0])
    for support_size in range(1, row_count + 1):
        for rows in combinations(range(row_count), support_size):
            for columns in combinations(range(column_count), support_size):
                coefficients = [[Fraction(matrix[row][column]) for row in rows] + [Fraction(-1)]
                                for column in columns]
                coefficients.append([Fraction(1)] * support_size + [Fraction(0)])
                right_sides = [Fraction(0)] * support_size + [Fraction(1)]
                solution = linear_solve(coefficients, right_sides)
                if solution is None:
                    continue
                probabilities = solution[:support_size]
                value = solution[support_size]
                if any(item < 0 for item in probabilities):
                    continue
                inner = [[Fraction(matrix[row][column]) for column in columns]
                         for row in rows[1:]]
                inner.append([Fraction(1)] * support_size)
                inner_sides = [value] * (support_size - 1) + [Fraction(1)]
                inner_solution = linear_solve(inner, inner_sides)
                if inner_solution is None:
                    continue
                if any(item < 0 for item in inner_solution):
                    continue
                valid = True
                for row in range(row_count):
                    expected = sum(inner_solution[index] * matrix[row][column]
                                   for index, column in enumerate(columns))
                    if expected > value:
                        valid = False
                        break
                if not valid:
                    continue
                for column in range(column_count):
                    expected = sum(probabilities[index] * matrix[row][column]
                                   for index, row in enumerate(rows))
                    if expected < value:
                        valid = False
                        break
                if valid:
                    return value
    raise AssertionError("no equilibrium found")


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        row_count = tokens[position]
        column_count = tokens[position + 1]
        position += 2
        matrix = []
        for _ in range(row_count):
            matrix.append(tokens[position:position + column_count])
            position += column_count
        answers.append(format_value(oracle_case(matrix)))
    return "\n".join(answers) + "\n"


SAMPLE = """3
1 1
-1
2 2
1 2
3 4
2 2
1 4
4 3
"""
SAMPLE_OUT = """-1.000
3.000
3.250
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 2\n5 -3\n") == "-3.000\n"
assert oracle("1\n2 2\n1 4\n4 3\n") == "3.250\n"
assert oracle("1\n2 3\n0 0 0\n0 0 0\n") == "0.000\n"
assert oracle("1\n3 3\n0 2 -1\n-2 0 1\n1 -1 0\n") == "0.000\n"
assert oracle("1\n3 4\n1 2 3 4\n5 6 7 8\n9 10 11 12\n") == "9.000\n"


def write(name, cases):
    parts = [str(len(cases))]
    for matrix in cases:
        parts.append(f"{len(matrix)} {len(matrix[0])}")
        for row in matrix:
            parts.append(" ".join(str(value) for value in row))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [[-5]],
        [[0, 0], [0, 0]],
        [[1, -1], [-1, 1]],
        [[-3, 7], [5, -2]],
        [[0, 2, -1], [-2, 0, 1], [1, -1, 0]],
    ])
    rng = random.Random(20261126)
    write("3_wide", [
        [[rng.randint(-150000, 150000) for _ in range(12)] for _ in range(2)],
        [[rng.randint(-150000, 150000) for _ in range(12)] for _ in range(3)],
    ])
    cases = []
    for _ in range(40):
        row_count = rng.randint(1, 3)
        column_count = rng.randint(1, 8)
        cases.append([[rng.randint(-100, 100) for _ in range(column_count)]
                      for _ in range(row_count)])
    write("4_random", cases)
    io_cases = [[[rng.randint(-1000, 1000) for _ in range(5)] for _ in range(2)]
                for _ in range(120)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
