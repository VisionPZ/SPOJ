#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for RF113.

The input holds square matrices, one dimension line then n rows.
The oracle indexes matrix[i][i] for every row and checks each value.
The solution checks scanned values at diagonal cell positions.
A zero dimension ends the input.
"""
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "2\n0 1\n3 0\n"
    "3\n0 1 2\n1 0 2\n4 2 0\n"
    "3\n1 2 3\n1 0 2\n4 2 0\n"
    "2\n0 1\n1 1\n"
    "0\n"
)
SAMPLE_OUTPUT = "true\ntrue\nfalse\nfalse\n"


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        dimension = int(tokens[cursor])
        cursor += 1
        if dimension == 0:
            break
        rows = []
        for _ in range(dimension):
            rows.append([int(value) for value in tokens[cursor:cursor + dimension]])
            cursor += dimension
        answers.append("true" if all(rows[i][i] == 0
                                     for i in range(dimension)) else "false")
    return "".join(answer + "\n" for answer in answers)


def write(name, matrices):
    parts = []
    for matrix in matrices:
        parts.append(str(len(matrix)) + "\n")
        for row in matrix:
            parts.append(" ".join(str(value) for value in row) + "\n")
    parts.append("0\n")
    input_text = "".join(parts)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert SAMPLE_OUTPUT == "true\ntrue\nfalse\nfalse\n"
assert oracle("1\n0\n0\n") == "true\n"
assert oracle("1\n5\n0\n") == "false\n"
assert oracle("2\n1 2\n3 0\n0\n") == "false\n"


def trace_example():
    for matrix in [[[0, 1], [3, 0]],
                   [[0, 1, 2], [1, 0, 2], [4, 2, 0]],
                   [[1, 2, 3], [1, 0, 2], [4, 2, 0]],
                   [[0, 1], [1, 1]]]:
        diagonal = [matrix[i][i] for i in range(len(matrix))]
        print("diagonal %s -> %s" % (
            diagonal, "true" if all(value == 0 for value in diagonal)
            else "false"))


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
    (ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE_INPUT))
    write("2_edges", [
        [[0]],
        [[9]],
        [[0, 0], [0, 0]],
        [[0, 1], [1, 0]],
        [[1, 0], [0, 1]],
    ])
    write("3_wide", [
        [[0 if row == col else 1 for col in range(50)] for row in range(50)],
        [[1 if row == col else 0 for col in range(50)] for row in range(50)],
    ])
    random.seed(2026)
    write("4_random", [
        [[random.choice([0, 0, 0, random.randint(1, 1000000)])
          for _ in range(size)]
         for _ in range(size)]
        for size in [random.randint(1, 10) for _ in range(300)]
    ])
    write("5_io", [
        [[0 if row == col else random.randint(1, 999999999)
          for col in range(30)] for row in range(30)]
        for _ in range(2000)
    ])


if "--trace" in sys.argv:
    trace_example()
else:
    main()
