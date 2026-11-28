#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        size = int(tokens[cursor]); cursor += 1
        if size == -1:
            break
        matrix = []
        for _ in range(size):
            matrix.append([int(tokens[cursor + column]) for column in range(size)])
            cursor += size
        rotations = [
            [tuple(row[(column + shift) % size] for column in range(size))
             for shift in range(size)]
            for row in matrix
        ]
        best = None
        for shifts in itertools.product(range(size), repeat=size):
            highest = max(
                sum(rotations[row][shifts[row]][column] for row in range(size))
                for column in range(size)
            )
            if best is None or highest < best:
                best = highest
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """2
4 6
3 7
3
1 2 3
4 5 6
7 8 9
-1
"""
SAMPLE_OUT = """11
15
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n-5\n-1\n") == "-5\n"
assert oracle("2\n1 2\n3 4\n-1\n") == "5\n"
assert oracle("2\n4 6\n3 7\n-1\n") == "11\n"
assert oracle("3\n0 0 0\n0 0 0\n0 0 0\n-1\n") == "0\n"


def write(name, matrices):
    chunks = []
    for matrix in matrices:
        chunks.append(str(len(matrix)) + "\n")
        chunks.extend(" ".join(str(value) for value in row) + "\n" for row in matrix)
    text = "".join(chunks) + "-1\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[[-9999]], [[0]], [[-3, 5], [7, -2]], [[-1, -2], [-3, -4]]])
    write("3_wide", [
        [[9999, -9999, 5000, -5000, 1, -1],
         [-9999, 9999, -5000, 5000, -1, 1],
         [5000, -5000, 9999, -9999, 2, -2],
         [-5000, 5000, -9999, 9999, -2, 2],
         [1, -1, 2, -2, 9999, -9999],
         [-1, 1, -2, 2, -9999, 9999]],
    ])
    rng = random.Random(20261126)
    random_matrices = []
    for _ in range(40):
        size = rng.randint(1, 5)
        random_matrices.append([
            [rng.randint(-9999, 9999) for _ in range(size)]
            for _ in range(size)
        ])
    write("4_random", random_matrices)
    write("5_io", [[[rng.randint(-9999, 9999)]] for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
