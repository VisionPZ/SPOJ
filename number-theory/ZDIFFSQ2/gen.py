#!/usr/bin/env python3
import random
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """15 32 57 90 131 180
"""
SAMPLE_OUT = """237 302 375
"""


def oracle(text):
    values = [int(value) for value in text.split()]
    if not values:
        return "0 0 0\n"
    leading = [values[0]]
    row = values[:]
    while len(row) > 1:
        row = [row[index + 1] - row[index] for index in range(len(row) - 1)]
        leading.append(row[0])
        if all(value == 0 for value in row):
            break
    answers = []
    for step in range(1, 4):
        index = len(values) - 1 + step
        total = sum(comb(index, order) * coefficient
                    for order, coefficient in enumerate(leading))
        answers.append(total)
    return " ".join(str(value) for value in answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 3 6 10 15\n") == "21 28 36\n"
assert oracle("5 5 5 5\n") == "5 5 5\n"
assert oracle("1 3 5 7\n") == "9 11 13\n"
assert oracle("2 -1 -4 -7\n") == "-10 -13 -16\n"
assert oracle("1 3 6\n") == "10 15 21\n"
assert oracle("-39 -188 -521\n") == "-1038 -1739 -2624\n"
assert oracle("-15 -20 -123 -462\n") == "-1175 -2400 -4275\n"


def polynomial_values(coefficients, count):
    return [sum(coefficient * (point ** degree)
                for degree, coefficient in enumerate(coefficients))
            for point in range(1, count + 1)]


def write(name, values):
    text = " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [7, 7, 7, 7, 7, 7])
    write("3_wide", polynomial_values([11, 7, 3, 2, 1], 9))
    rng = random.Random(20261126)
    write("4_random", polynomial_values([rng.randint(-50, 50) for _ in range(4)], 8))
    write("5_io", polynomial_values([1000, 500, 250, 125, 64], 9))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
