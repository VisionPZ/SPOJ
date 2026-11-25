#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 98765431


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cow_count = tokens[0]
    repeat_count = tokens[1]
    values = tokens[2:2 + cow_count]
    matrix = (((-1) % MODULUS, 1, 0, (cow_count - 1) % MODULUS))
    result = (1, 0, 0, 1)
    exponent = repeat_count
    while exponent:
        if exponent & 1:
            result = (
                (result[0] * matrix[0] + result[1] * matrix[2]) % MODULUS,
                (result[0] * matrix[1] + result[1] * matrix[3]) % MODULUS,
                (result[2] * matrix[0] + result[3] * matrix[2]) % MODULUS,
                (result[2] * matrix[1] + result[3] * matrix[3]) % MODULUS,
            )
        matrix = (
            (matrix[0] * matrix[0] + matrix[1] * matrix[2]) % MODULUS,
            (matrix[0] * matrix[1] + matrix[1] * matrix[3]) % MODULUS,
            (matrix[2] * matrix[0] + matrix[3] * matrix[2]) % MODULUS,
            (matrix[2] * matrix[1] + matrix[3] * matrix[3]) % MODULUS,
        )
        exponent //= 2
    initial_total = sum(values) % MODULUS
    answers = [
        str((result[0] * value + result[1] * initial_total) % MODULUS)
        for value in values
    ]
    return "\n".join(answers) + "\n"


SAMPLE = """3 4
1
0
4
"""
SAMPLE_OUT = """26
25
29
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n7\n") == "0\n"
assert oracle("2 2\n5 7\n") == "5\n7\n"
assert oracle("3 4\n1 0 4\n") == SAMPLE_OUT
assert pow(3, 4, 7) == 4


def write(name, cow_count, repeat_count, values):
    text = f"{cow_count} {repeat_count}\n" + "".join(
        f"{value}\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, [0])
    write("3_wide", 50, 1414213562, [89999999] * 50)
    rng = random.Random(20261126)
    write("4_random", 500, rng.randint(1, 1414213562),
          [rng.randint(0, 89999999) for _ in range(500)])
    write("5_io", 20000, 1414213562,
          [rng.randint(0, 89999999) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, 4, [1, 0, 4])
build()
