#!/usr/bin/env python3
import cmath
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(base_value, exponent_value):
    series_sum = 0
    term = 1
    for _ in range(exponent_value):
        series_sum += term
        term *= base_value
    denominator = base_value - 1
    numerator = series_sum * denominator
    assert numerator == base_value ** exponent_value - 1
    return f"{numerator}/{denominator}"


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    cursor = 1
    for _ in range(case_count):
        base_value = int(tokens[cursor])
        exponent_value = int(tokens[cursor + 1])
        cursor += 2
        answers.append(oracle_case(base_value, exponent_value))
    return "\n".join(answers) + "\n"


SAMPLE = """1
5 10
"""
SAMPLE_OUT = """9765624/4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(2, 2) == "3/1"
assert oracle_case(3, 2) == "8/2"
assert oracle_case(10, 3) == "999/9"
assert oracle_case(1000, 2) == "999999/999"

product_value = 1
for root_index in range(1, 5):
    root = cmath.exp(2j * math.pi * root_index / 5)
    product_value *= (5 - root)
assert abs(product_value - 781) < 1e-6


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(
        f"{base_value} {exponent_value}\n" for base_value, exponent_value in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 2), (2, 3), (3, 2), (10, 3), (1000, 2), (1000, 3)])
    write("3_wide", [(1000, 1000), (999, 999), (2, 1000)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(2, 1000), rng.randint(2, 1000))
                       for _ in range(40)])
    write("5_io", [(1000, 1000)] * 60)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5, 10)])
build()
