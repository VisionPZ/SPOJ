#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for RF112.

The input holds square matrices, one dimension line then n rows.
The oracle builds rows and sums each column with zip and sum.
The solution adds each scanned value into a flat running column array.
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
SAMPLE_OUTPUT = "3,1\n5,3,4\n6,4,5\n1,2\n"


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
        answers.append(",".join(str(sum(column)) for column in zip(*rows)))
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
assert SAMPLE_OUTPUT == "3,1\n5,3,4\n6,4,5\n1,2\n"
assert oracle("1\n7\n0\n") == "7\n"
assert oracle("2\n0 0\n0 0\n0\n") == "0,0\n"


def trace_example():
    matrix = [[0, 1, 2], [1, 0, 2], [4, 2, 0]]
    print("rows: %s" % matrix)
    print("columns: %s" % list(zip(*matrix)))
    print("totals: %s" % ",".join(str(sum(column)) for column in zip(*matrix)))


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
    (ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE_INPUT))
    write("2_edges", [
        [[1]],
        [[0, 0], [0, 0]],
        [[1000000000, 999999999], [1, 2]],
        [[5, 6, 7], [8, 9, 10], [11, 12, 13]],
    ])
    write("3_wide", [
        [[1000000 + row * 50 + col for col in range(50)] for row in range(50)],
        [[0 for _ in range(50)] for _ in range(50)],
    ])
    random.seed(2026)
    write("4_random", [
        [[random.randint(0, 1000000) for _ in range(size)]
         for _ in range(size)]
        for size in [random.randint(1, 10) for _ in range(300)]
    ])
    write("5_io", [
        [[random.randint(0, 999999999) for _ in range(30)] for _ in range(30)]
        for _ in range(2000)
    ])


if "--trace" in sys.argv:
    trace_example()
else:
    main()
