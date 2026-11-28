#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(matrix):
    size = len(matrix)
    best = None
    for columns in itertools.permutations(range(size)):
        chosen = [matrix[row][column] for row, column in enumerate(columns)]
        for signs in itertools.product((1, -1), repeat=size):
            total = sum(value * sign for value, sign in zip(chosen, signs))
            magnitude = abs(total)
            if best is None or magnitude < best:
                best = magnitude
                if best == 0:
                    return 0
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(count):
        size = tokens[cursor]
        cursor += 1
        matrix = []
        for _ in range(size):
            matrix.append(tokens[cursor:cursor + size])
            cursor += size
        answers.append(str(oracle_case(matrix)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
2
1 5
4 3
3
1 75 10
22 500 3
9 125 50
"""
SAMPLE_OUT = """1
3
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n7\n") == "7\n"
assert oracle("1\n2\n1 2\n3 4\n") == "1\n"
assert oracle("1\n3\n1 1 1\n1 1 1\n1 1 1\n") == "1\n"
assert oracle("1\n2\n-5 9\n2 -3\n") == "2\n"


def write_case(name, matrices):
    chunks = [str(len(matrices))]
    for matrix in matrices:
        chunks.append(str(len(matrix)))
        for row in matrix:
            chunks.append(" ".join(str(value) for value in row))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [[[7]], [[-5, 9], [2, -3]],
                           [[1, 2, 3], [4, 5, 6], [7, 8, 9]]])
    rng = random.Random(20261126)
    wide = [[rng.randint(1, 2000000000) for _ in range(6)] for _ in range(6)]
    write_case("3_wide", [wide])
    random_matrices = []
    for _ in range(4):
        size = rng.choice([4, 5, 6])
        random_matrices.append([[rng.randint(1, 100000) for _ in range(size)]
                                for _ in range(size)])
    write_case("4_random", random_matrices)
    many = []
    for _ in range(2000):
        many.append([[rng.randint(0, 10**8)]])
    write_case("5_io", many)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
