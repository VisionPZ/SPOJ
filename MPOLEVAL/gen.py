#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    degree = int(tokens[0])
    start = int(tokens[1])
    answers = int(tokens[2])
    digits = int(tokens[3])
    coefficients = [int(value) for value in tokens[4:4 + degree + 1]]
    lines = []
    for offset in range(answers):
        point = start + offset
        value = coefficients[0]
        for coefficient in coefficients[1:]:
            value = value * point + coefficient
        suffix = str(value).zfill(digits)[-digits:]
        lines.append(str(sum(int(character) ** 2 for character in suffix)))
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = """3 0 10 2
1
0
2
1
"""
SAMPLE_OUT = """1
16
10
25
58
45
85
89
85
80
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0 0 3 1\n999\n") == "81\n81\n81\n"
assert oracle("1 0 2 3\n2\n5\n") == "25\n49\n"
assert oracle("1 " + "1" + "0" * 50 + " 2 5\n1\n0\n") == "0\n1\n"
assert len(SAMPLE_OUT.splitlines()) == 10


def build_input(degree, start, answers, digits, coefficients):
    lines = [f"{degree} {start} {answers} {digits}"]
    lines.extend(str(coefficient) for coefficient in coefficients)
    return "\n".join(lines) + "\n"


def write(name, degree, start, answers, digits, coefficients):
    text = build_input(degree, start, answers, digits, coefficients)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_number(rng, maximum_digits):
    length = rng.randint(1, maximum_digits)
    return int("".join(str(rng.randint(1, 9)) if index == 0 else str(rng.randint(0, 9))
                       for index in range(length)))


def build():
    write("2_edges", 0, 0, 3, 1, [999])
    rng = random.Random(20261126)
    write("3_wide", 10, random_number(rng, 60), 20, 300,
          [random_number(rng, 1000) for _ in range(11)])
    write("4_random", rng.randint(0, 10), random_number(rng, 80), 50,
          rng.randint(1, 50), [random_number(rng, 80) for _ in range(11)])
    write("5_io", 10, random_number(rng, 40), 1000, 30,
          [random_number(rng, 40) for _ in range(11)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, 0, 10, 2, [1, 0, 2, 1])
build()
