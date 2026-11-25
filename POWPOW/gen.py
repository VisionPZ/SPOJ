#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def oracle_case(base, power, size):
    coefficient = 1
    exponent = 0
    for index in range(size + 1):
        exponent += coefficient * coefficient
        if index < size:
            coefficient = coefficient * (size - index) // (index + 1)
    return pow(base, pow(exponent, power, MOD - 1), MOD)


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    position = 1
    for _ in range(case_count):
        base = int(tokens[position])
        power = int(tokens[position + 1])
        size = int(tokens[position + 2])
        position += 3
        answers.append(str(oracle_case(base, power, size)))
    return "\n".join(answers) + "\n"


SAMPLE = """1
1 1 1
"""
SAMPLE_OUT = """1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(1, 1, 1) == 1
assert oracle_case(2, 1, 0) == 2
assert oracle_case(0, 3, 5) == 0
assert oracle_case(3, 2, 2) == pow(3, 36, MOD)


def write(name, cases):
    lines = [str(len(cases))] + [" ".join(str(value) for value in case) for case in cases]
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0, 0), (0, 5, 3), (1, 0, 5), (5, 1, 0), (2, 2, 2)])
    write("3_wide", [(5, 3, 5000), (100000, 5, 4999), (1, 100000, 5000)])
    rng = random.Random(20261126)
    write("4_random", [
        (rng.randint(0, 100000), rng.randint(0, 100000), rng.randint(0, 2000))
        for _ in range(100)
    ])
    write("5_io", [
        (rng.randint(0, 100000), rng.randint(0, 100000), rng.randint(0, 2000))
        for _ in range(1000)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
