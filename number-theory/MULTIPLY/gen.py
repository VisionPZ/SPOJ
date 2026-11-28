#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def peasant(first, second):
    total = 0
    left = first
    right = second
    while right > 0:
        if right & 1:
            total += left
        left += left
        right >>= 1
    return total


def oracle(text):
    tokens = text.split()
    answers = []
    k = 0
    while k < len(tokens):
        first = int(tokens[k]); k += 1
        second = int(tokens[k]); k += 1
        answers.append(str(peasant(first, second)))
    return "\n".join(answers) + "\n"


SAMPLE = [(1, 2)]
assert peasant(1, 2) == 2
assert peasant(99, 101) == 9999
assert peasant(101, 99) == 9999
assert peasant(1, 9999) == 9999
assert peasant(9999, 1) == 9999
assert oracle("1\n2\n") == "2\n"


def write(name, pairs):
    input_text = "".join(f"{first}\n{second}\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, 1), (9999, 1), (1, 9999), (99, 101),
                      (101, 99), (99, 99), (100, 99), (2, 4999)])
    write("3_wide", [(101, 99), (99, 101), (5000, 1), (1, 9999),
                     (9998, 1), (2, 4999), (100, 99), (90, 111)])

    random.seed(2026)
    pairs = []
    for _ in range(200):
        first = random.randint(1, 9999)
        second = random.randint(1, 9999 // first)
        pairs.append((first, second))
    write("4_random", pairs)

    pairs = []
    for _ in range(5000):
        first = random.randint(1, 9999)
        second = random.randint(1, 9999 // first)
        pairs.append((first, second))
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
