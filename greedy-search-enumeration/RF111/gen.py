#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for RF111.

Each line holds a matrix of competitor prices and a vector of diner counts.
The oracle accumulates column contributions into every restaurant total.
The solution scans bytes once and takes a row-wise dot product.
"""
import random
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "{{400,2500,30000,50000}, {5200,4300,6000,8500}, "
    "{400,504,520,6300}}; {10, 20, 100, 50}\n"
)
SAMPLE_OUTPUT = '"{5554000,1163000,381080} – 381080"\n'

NUMBER_PATTERN = re.compile(r"-?\d+")


def oracle(text):
    answers = []
    for raw_line in text.splitlines():
        if not raw_line.strip():
            continue
        matrix_text, weight_text = raw_line.split(";", 1)
        matrix = [int(value) for value in NUMBER_PATTERN.findall(matrix_text)]
        weights = [int(value) for value in NUMBER_PATTERN.findall(weight_text)]
        if not weights or not matrix:
            continue
        columns = len(weights)
        row_count = len(matrix) // columns
        if row_count == 0:
            continue
        prices = [0] * row_count
        for column, weight in enumerate(weights):
            for row in range(row_count):
                prices[row] += matrix[row * columns + column] * weight
        answers.append('"{%s} – %d"\n' % (
            ",".join(str(price) for price in prices), min(prices)))
    return "".join(answers)


def write(name, cases):
    input_text = "".join(case + "\n" for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def case(matrix, weights, nested=False):
    rows = "{" + ", ".join("{" + ", ".join(str(value) for value in row) + "}"
                           for row in matrix) + "}"
    if nested:
        vector = "{" + ", ".join("{%d}" % value for value in weights) + "}"
    else:
        vector = "{" + ", ".join(str(value) for value in weights) + "}"
    return rows + "; " + vector


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert SAMPLE_OUTPUT == '"{5554000,1163000,381080} – 381080"\n'
assert oracle("{{50000}, {6000}, {6300}}; {10}\n") == (
    '"{500000,60000,63000} – 60000"\n')
assert oracle("{{400,2500,30000,50000}, {5200,4300,6000,8500}, "
              "{400,504,520,6300}}; {0, 20, 0, 50}\n") == (
    '"{2550000,511000,325080} – 325080"\n')


def trace_example():
    matrix = [[400, 2500, 30000, 50000],
              [5200, 4300, 6000, 8500],
              [400, 504, 520, 6300]]
    weights = [10, 20, 100, 50]
    for row_index, row in enumerate(matrix, 1):
        terms = " + ".join("%d*%d" % pair for pair in zip(row, weights))
        print("row %d: %s = %d" % (row_index, terms,
                                   sum(a * b for a, b in zip(row, weights))))
    print("lowest: %d" % min(sum(a * b for a, b in zip(row, weights))
                             for row in matrix))


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
    (ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE_INPUT))
    write("2_edges", [
        case([[7]], [3]),
        case([[0, 0], [0, 0]], [5, 9]),
        case([[1000000]], [1000000]),
        case([[50000], [6000], [6300]], [10], nested=True),
        case([[1, 2, 3]], [0, 0, 0]),
    ])
    random.seed(2026)
    write("3_wide", [
        case([[random.randint(1, 100000) for _ in range(50)]
              for _ in range(3)], [random.randint(1, 100) for _ in range(50)])
        for _ in range(3)
    ])
    write("4_random", [
        case([[random.randint(0, 10000)
               for _ in range(random.randint(1, 6))]
              for _ in range(random.randint(1, 5))],
             [random.randint(0, 100) for _ in range(random.randint(1, 6))])
        for _ in range(200)
    ])
    write("5_io", [
        "{%s, %s, %s}; {%d, %d, %d, %d}" % (
            ",".join(str(random.randint(100, 50000)) for _ in range(4)),
            ",".join(str(random.randint(100, 50000)) for _ in range(4)),
            ",".join(str(random.randint(100, 50000)) for _ in range(4)),
            random.randint(1, 100), random.randint(1, 100),
            random.randint(1, 100), random.randint(1, 100))
        for _ in range(5000)
    ])


if "--trace" in sys.argv:
    trace_example()
else:
    main()
