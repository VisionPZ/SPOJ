#!/usr/bin/env python3
import math
import random
from pathlib import Path

from sympy.solvers.diophantine.diophantine import diop_DN

ROOT = Path(__file__).resolve().parent


def fundamental(n):
    for candidate in diop_DN(n, 1):
        if candidate[0] > 0 and candidate[1] > 0:
            return candidate
    raise ValueError(n)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for index in range(case_count):
        value = tokens[index + 1]
        x_value, y_value = fundamental(value)
        answers.append(f"{x_value} {y_value}")
    return "\n".join(answers) + "\n"


SAMPLE = "3\n2\n6\n61\n"
SAMPLE_OUT = "3 2\n5 2\n1766319049 226153980\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert fundamental(2) == (3, 2)
assert fundamental(6) == (5, 2)
assert fundamental(13) == (649, 180)
assert fundamental(19) == (170, 39)
assert fundamental(61) == (1766319049, 226153980)

CANDIDATES = []
for value in range(2, 1001):
    root = math.isqrt(value)
    if root * root == value:
        continue
    x_value, y_value = fundamental(value)
    if x_value < 10**18 and y_value < 10**18:
        CANDIDATES.append(value)


def write(name, values):
    text = str(len(values)) + "\n" + "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [2, 3, 6, 10, 61])
    write("3_wide", [13, 19, 61, 109, 181])
    rng = random.Random(20261126)
    write("4_random", [rng.choice(CANDIDATES) for _ in range(30)])
    biggest = sorted(CANDIDATES, key=lambda value: fundamental(value)[0], reverse=True)[:40]
    write("5_io", biggest)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 6, 61])
build()
