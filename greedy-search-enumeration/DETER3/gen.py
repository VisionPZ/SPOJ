#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def determinant(matrix):
    size = len(matrix)
    rows = [[Fraction(value) for value in row] for row in matrix]
    sign = 1
    product = Fraction(1)
    for column in range(size):
        pivot_row = None
        for row in range(column, size):
            if rows[row][column] != 0:
                pivot_row = row
                break
        if pivot_row is None:
            return 0
        if pivot_row != column:
            rows[column], rows[pivot_row] = rows[pivot_row], rows[column]
            sign = -sign
        pivot = rows[column][column]
        product *= pivot
        for row in range(column + 1, size):
            if rows[row][column] == 0:
                continue
            factor = rows[row][column] / pivot
            for index in range(column + 1, size):
                rows[row][index] -= factor * rows[column][index]
            rows[row][column] = Fraction(0)
    return sign * product


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        size = int(tokens[cursor]); cursor += 1
        modulus = int(tokens[cursor]); cursor += 1
        matrix = []
        for _ in range(size):
            matrix.append([int(tokens[cursor + index]) for index in range(size)])
            cursor += size
        answers.append(str(int(determinant(matrix)) % modulus))
    return "\n".join(answers) + "\n"


SAMPLE = """1 10
-528261590
2 2
595698392 -398355861
603279964 -232703411
3 4
-840419217 -895520213 -303215897
537496093 181887787 -957451145
-305184545 584351123 -257712188
"""
SAMPLE_OUT = """0
0
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 7\n1 0 0\n0 1 0\n0 0 1\n") == "1\n"
assert oracle("2 4\n2 0\n0 2\n") == "0\n"
assert oracle("2 5\n1 2\n3 4\n") == "3\n"
assert oracle("2 7\n2 3\n2 3\n") == "0\n"


def write(name, cases):
    chunks = []
    for size, modulus, matrix in cases:
        chunks.append(f"{size} {modulus}\n")
        chunks.append("".join(" ".join(str(value) for value in row) + "\n"
                              for row in matrix))
    input_text = "".join(chunks)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_matrix(size, rng, low=-10 ** 9, high=10 ** 9):
    return [[rng.randint(low, high) for _ in range(size)] for _ in range(size)]


def build():
    write("2_edges", [
        (1, 10, [[-528261590]]),
        (2, 2, [[595698392, -398355861], [603279964, -232703411]]),
        (3, 1, [[1, 2, 3], [4, 5, 6], [7, 8, 9]]),
        (2, 4, [[2, 3], [4, 6]]),
        (4, 9, [[0, 0, 0, 0], [1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12]]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [(18, 999999937, random_matrix(18, rng))])
    random_cases = []
    for size, modulus in [(12, 1000000000), (14, 999999989), (16, 360)]:
        random_cases.append((size, modulus, random_matrix(size, rng)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(40):
        io_cases.append((4, rng.randint(2, 1000000000), random_matrix(4, rng)))
    write("5_io", io_cases)
    big_chunks = []
    for size, modulus in [(200, 1000000000), (200, 999999937), (200, 999999999)]:
        matrix = random_matrix(size, rng)
        big_chunks.append(f"{size} {modulus}\n")
        big_chunks.append("".join(" ".join(str(value) for value in row) + "\n"
                                  for row in matrix))
    Path("/tmp/DETER3_big.txt").write_text("".join(big_chunks))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
