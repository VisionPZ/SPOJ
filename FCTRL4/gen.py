#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 10 ** 20


def oracle(text):
    tokens = [int(token) for token in text.split()]
    if not tokens:
        return ""
    stripped_factorial = 1
    last_digits = {0: "1"}
    for value in range(1, max(tokens) + 1):
        stripped_factorial = (stripped_factorial * value) % MODULUS
        while stripped_factorial % 10 == 0:
            stripped_factorial //= 10
        last_digits[value] = str(stripped_factorial % 10)
    return "\n".join(last_digits[token] for token in tokens) + "\n"


SAMPLE = """1
2
3
4
5
6
7
8
"""
SAMPLE_OUT = """1
2
6
4
2
2
4
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("4\n") == "4\n"
assert oracle("5\n") == "2\n"
assert oracle("25\n") == "4\n"
assert oracle("0\n") == "1\n"
assert oracle("100\n") == "4\n"


def write(name, numbers):
    text = "\n".join(str(value) for value in numbers) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 24, 25, 26, 124, 125])
    write("3_wide", [999, 1000, 1499, 1500, 1999, 2000, 4999, 5000, 9999, 10000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 4000) for _ in range(200)])
    write("5_io", [rng.randint(0, 20000) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 4, 5, 6, 7, 8])
build()
