#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def matrix_multiply(left, right, modulus):
    return [[(left[row][0] * right[0][col] + left[row][1] * right[1][col]) % modulus
             for col in range(2)] for row in range(2)]


def fibonacci_matrix(index_value, modulus):
    base = [[1, 1], [1, 0]]
    result = [[1, 0], [0, 1]]
    exponent = index_value - 1
    while exponent > 0:
        if exponent & 1:
            result = matrix_multiply(result, base, modulus)
        base = matrix_multiply(base, base, modulus)
        exponent >>= 1
    return result[0][0]


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        months = int(tokens[cursor]); cursor += 1
        exponent = int(tokens[cursor]); cursor += 1
        capacity = 1 << exponent
        adults = fibonacci_matrix(months + 1, capacity)
        answers.append(str(adults % capacity))
    return "\n".join(answers) + "\n"


SAMPLE = "1\n5 2\n"
SAMPLE_OUT = "0\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert fibonacci_matrix(2, 1 << 20) == 1
assert fibonacci_matrix(6, 1 << 20) == 8
assert fibonacci_matrix(5, 1 << 20) == 5
assert oracle("2\n4 2\n5 2\n") == "1\n0\n"


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{months} {exponent}\n" for months, exponent in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (2, 1), (3, 1), (4, 2), (5, 2), (6, 3), (7, 4)])
    write("3_wide", [(2147483647, 20), (2147483646, 19), (2147483645, 1),
                      (1000000000, 20), (999999999, 11)])
    rng = random.Random(20261126)
    pairs = [(rng.randint(1, 2147483647), rng.randint(1, 20)) for _ in range(100)]
    write("4_random", pairs)
    write("5_io", [(rng.randint(1, 2147483647), rng.randint(1, 20)) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5, 2)])
build()
