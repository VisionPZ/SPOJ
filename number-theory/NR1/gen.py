#!/usr/bin/env python3
import random
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_one(degree, difference_order, coefficients):
    coefficients = list(coefficients)

    def evaluate(point):
        value = 0
        for exponent in range(degree + 1):
            value += coefficients[exponent] * point ** exponent
        return value

    return sum((-1) ** (difference_order - index)
               * comb(difference_order, index) * evaluate(index)
               for index in range(difference_order + 1))


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        degree = int(tokens[cursor]); cursor += 1
        difference_order = int(tokens[cursor]); cursor += 1
        coefficients = [int(value) for value in tokens[cursor:cursor + degree + 1]]
        cursor += degree + 1
        monomial_coefficients = list(reversed(coefficients))
        answers.append(str(oracle_one(degree, difference_order,
                                     monomial_coefficients)))
    return "\n".join(answers) + "\n"


SAMPLE = """1
3 2
2 -3 3 -10
"""
SAMPLE_OUT = """6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_one(3, 2, [-10, 3, -3, 2]) == 6
assert oracle_one(3, 1, [-10, 3, -3, 2]) == 2
assert oracle_one(0, 0, [7]) == 7
assert oracle_one(2, 0, [-39, 20, 4]) == -39
assert oracle_one(4, 4, [1, 2, 3, 4, 5]) == 120
assert oracle_one(25, 18, [50] * 26) == 1078986540875285079797760000000


def write(name, cases):
    input_text = str(len(cases)) + "\n"
    for degree, difference_order, monomial_coefficients in cases:
        input_text += f"{degree} {difference_order}\n"
        input_text += " ".join(str(value)
                               for value in reversed(monomial_coefficients)) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    edge_cases = [
        (0, 0, [7]),
        (1, 0, [-39, 20]),
        (1, 1, [0, 50]),
        (2, 2, [1, 0, 0]),
        (5, 5, [50] * 6),
        (3, 0, [-50, 0, 0, 50]),
    ]
    write("2_edges", edge_cases)
    rng = random.Random(20261126)
    wide_cases = []
    for _ in range(18):
        difference_order = rng.randint(0, 25)
        wide_cases.append((25, difference_order,
                           [rng.choice([-50, -1, 0, 1, 50]) for _ in range(26)]))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(25):
        degree = rng.randint(0, 25)
        difference_order = rng.randint(0, degree)
        random_cases.append((degree, difference_order,
                             [rng.randint(-50, 50) for _ in range(degree + 1)]))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(29):
        difference_order = rng.randint(18, 25)
        io_cases.append((25, difference_order,
                         [rng.randint(-50, 50) for _ in range(26)]))
    write("5_io", io_cases)
    Path("/tmp/NR1_big.txt").write_text((ROOT / "in" / "5_io.txt").read_text())


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 2, [-10, 3, -3, 2])])
build()
