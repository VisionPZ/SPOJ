#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1234567891


def solve(limit_value, power):
    degree = power + 2
    values = []
    inner_total = 0
    outer_total = 0
    for value in range(degree + 1):
        if value > 0:
            inner_total = (inner_total + pow(value, power, MODULUS)) % MODULUS
            outer_total = (outer_total + inner_total) % MODULUS
        values.append(outer_total)
    differences = values[:]
    for order in range(1, degree + 1):
        for index in range(degree, order - 1, -1):
            differences[index] = (differences[index] - differences[index - 1]) % MODULUS
    result = 0
    combination = 1
    for order in range(degree + 1):
        result = (result + combination * differences[order]) % MODULUS
        combination = combination * ((limit_value - order) % MODULUS) % MODULUS
        combination = combination * pow(order + 1, MODULUS - 2, MODULUS) % MODULUS
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    lines = []
    for _ in range(case_count):
        limit_value = tokens[cursor]
        power = tokens[cursor + 1]
        cursor += 2
        lines.append(str(solve(limit_value, power)))
    return "\n".join(lines) + "\n"


SAMPLE = """5
2 3
10 3
3 3
100 0
100 1
"""
SAMPLE_OUT = """10
7942
46
5050
171700
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert solve(1, 0) == 1
assert solve(100, 1) == 171700
assert solve(3, 3) == 46
assert solve(3100, 0) == 4806550
assert solve(5, 2) == 105


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{limit_value} {power}\n" for limit_value, power in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 0), (1, 321), (2, 1), (123456789, 0)])
    write("3_wide", [(123456789, 321), (123456789, 0), (123456789, 1)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 123456789), rng.randint(0, 321)) for _ in range(12)])
    write("5_io", [(rng.randint(1, 10000), rng.randint(0, 20)) for _ in range(60)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
