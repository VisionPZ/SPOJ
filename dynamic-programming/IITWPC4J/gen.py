#!/usr/bin/env python3
import math
import random
from itertools import permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def ryser(matrix):
    size = len(matrix)
    total = []
    for mask in range(1 << size):
        row_products = []
        for row in matrix:
            row_products.append(sum(row[column] for column in range(size) if mask >> column & 1))
        product = 1.0
        for value in row_products:
            product *= value
        sign = 1 if (size - bin(mask).count("1")) % 2 == 0 else -1
        total.append(sign * product)
    return math.fsum(total)


def brute(matrix):
    total = 0.0
    for assignment in permutations(range(len(matrix))):
        product = 1.0
        for row, column in enumerate(assignment):
            product *= matrix[row][column]
        total += product
    return total


def oracle(text):
    tokens = text.split()
    position = 0
    test_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(test_count):
        size = int(tokens[position])
        position += 1
        matrix = []
        for _ in range(size):
            matrix.append([float(tokens[position + column]) for column in range(size)])
            position += size
        answers.append(f"{ryser(matrix):.6f}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
2
1 0
0 1
2
0.5 0.5
0.5 0.5
"""
SAMPLE_OUT = """1.000000
0.500000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n1\n") == "1.000000\n"
assert oracle("1\n2\n1 0\n1 0\n") == "0.000000\n"
assert abs(ryser([[0.5, 0.5], [0.5, 0.5]]) - brute([[0.5, 0.5], [0.5, 0.5]])) < 1e-12
assert abs(ryser([[0.2, 0.8], [0.3, 0.7]]) - brute([[0.2, 0.8], [0.3, 0.7]])) < 1e-12


def matrix_text(matrix):
    return "\n".join(" ".join(f"{value:.6f}" for value in row) for row in matrix) + "\n"


def write(name, matrices):
    text = str(len(matrices)) + "\n"
    for matrix in matrices:
        text += str(len(matrix)) + "\n" + matrix_text(matrix)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_matrix(rng, size):
    rows = [[rng.randint(0, 1000000) for _ in range(size)] for _ in range(size)]
    return [[round(value / sum(row), 6) for value in row] for row in rows]


def build():
    identity_three = [[1.0 if row == column else 0.0 for column in range(3)]
                      for row in range(3)]
    write("2_edges", [[[1.0]], identity_three, [[1.0, 0.0], [1.0, 0.0]]])
    write("3_wide", [[[1.0 if row == column else 0.0 for column in range(15)]
                      for row in range(15)]])
    rng = random.Random(20261126)
    write("4_random", [random_matrix(rng, rng.randint(2, 8)) for _ in range(5)])
    write("5_io", [random_matrix(rng, 15) for _ in range(19)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[[1.0, 0.0], [0.0, 1.0]], [[0.5, 0.5], [0.5, 0.5]]])
build()
