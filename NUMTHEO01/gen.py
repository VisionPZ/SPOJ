#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(count):
        factorial_limit = tokens[cursor]
        modulus = tokens[cursor + 1]
        cursor += 2
        product = 1
        for value in range(1, factorial_limit + 1):
            product *= value
            if value % 64 == 0:
                product %= modulus
        answers.append(str(product % modulus))
    return "\n".join(answers) + "\n"


SAMPLE = """3
5 7
10 231
1 1
"""
SAMPLE_OUT = """1
21
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert math.factorial(5) % 7 == 1
assert math.factorial(10) % 231 == 21
assert math.factorial(1) % 1 == 0
assert math.factorial(20) % 999999999999999 == 902008176642432


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{factorial_limit} {modulus}\n" for factorial_limit, modulus in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(0, 7), (1, 1), (2, 2), (13, 13), (20, 999999999999999)])
    write("3_wide", [(100000, 999999999999999), (8388699, 999999999999989)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(15):
        pairs.append((rng.randint(0, 200000), rng.randint(1, 999999999999999)))
    write("4_random", pairs)
    write("5_io", [(rng.randint(100000, 300000), rng.randint(10 ** 14, 999999999999999))
                   for _ in range(15)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5, 7), (10, 231), (1, 1)])
build()
