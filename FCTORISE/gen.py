#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def factor_by_search(number):
    offset = 0
    while True:
        candidate = number + offset * offset
        root = math.isqrt(candidate)
        if root * root == candidate:
            return root, offset, root + offset, root - offset
        offset += 1


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    lines = []
    for index in range(case_count):
        number = tokens[1 + index]
        upper, lower, product_a, product_b = factor_by_search(number)
        lines.append(f"{number} = {upper}^2 - {lower}^2 = {product_a}*{product_b}")
    return "\n".join(lines) + "\n"


SAMPLE = """2
15
9929
"""
SAMPLE_OUT = """15 = 4^2 - 1^2 = 5*3
9929 = 4965^2 - 4964^2 = 9929*1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n") == "3 = 2^2 - 1^2 = 3*1\n"
assert oracle("1\n9\n") == "9 = 3^2 - 0^2 = 3*3\n"
assert oracle("1\n45\n") == "45 = 7^2 - 2^2 = 9*5\n"
assert oracle("1\n21\n") == "21 = 5^2 - 2^2 = 7*3\n"
assert factor_by_search(15)[:2] == (4, 1)


def write(name, numbers):
    text = f"{len(numbers)}\n" + "".join(f"{number}\n" for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [3, 5, 9, 15, 21, 45])
    write("3_wide", [99991, 99991, 9991])
    rng = random.Random(20261126)
    numbers = [2 * rng.randint(1, 9000) + 1 for _ in range(40)]
    write("4_random", numbers)
    write("5_io", [9973 for _ in range(400)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
