#!/usr/bin/env python3
import random
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent

PLACES = (1000, 100, 10, 1)
LETTERS = "mcxi"


def render(digits):
    parts = []
    for letter, digit in zip(LETTERS, digits):
        if digit >= 2:
            parts.append(str(digit))
        if digit >= 1:
            parts.append(letter)
    return "".join(parts)


TABLE = {}
for digits in product(range(10), repeat=4):
    amount = sum(digit * place for digit, place in zip(digits, PLACES))
    TABLE[render(digits)] = amount
assert len(TABLE) == 10000
REVERSE = {amount: text for text, amount in TABLE.items()}


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    lines = []
    position = 1
    for _ in range(count):
        amount = TABLE[tokens[position]] + TABLE[tokens[position + 1]]
        position += 2
        lines.append(REVERSE[amount])
    return "\n".join(lines) + "\n"


SAMPLE = """10
xi x9i
i 9i
c2x2i 4c8x8i
m2ci 4m7c9x8i
9c9x9i i
i 9m9c9x8i
m i
i m
m9i i
9m8c7xi c2x8i
"""
SAMPLE_OUT = """3x
x
6cx
5m9c9x9i
m
9m9c9x9i
mi
mi
mx
9m9c9x9i
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\ni 9i\n") == "x\n"
assert oracle("1\nm i\n") == "mi\n"
assert oracle("1\nc2x2i 4c8x8i\n") == "6cx\n"
assert TABLE["5m2c3x4i"] == 5234


def amount_text(amount):
    return REVERSE[amount]


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(
        amount_text(first) + " " + amount_text(second) + "\n"
        for first, second in pairs
    )
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (9, 90), (999, 9000), (9998, 1)])
    rng = random.Random(20261126)
    wide = []
    for _ in range(500):
        first = rng.randint(5000, 9000)
        wide.append((first, rng.randint(1, 9999 - first)))
    write("3_wide", wide)
    pairs = []
    for _ in range(500):
        first = rng.randint(1, 9998)
        second = rng.randint(1, 9999 - first)
        pairs.append((first, second))
    write("4_random", pairs)
    write("5_io", [(9998, 1)] * 500)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
