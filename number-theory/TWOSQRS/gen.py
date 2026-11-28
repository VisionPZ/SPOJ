#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_square(value):
    root = math.isqrt(value)
    return root * root == value


def brute(value):
    for first in range(math.isqrt(value) + 1):
        if is_square(value - first * first):
            return True
    return False


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    answers = []
    for index in range(count):
        value = int(tokens[index + 1])
        answers.append("Yes" if brute(value) else "No")
    return "\n".join(answers) + "\n"


def write(name, values):
    input_text = str(len(values)) + "\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_VALUES = [1, 2, 7, 14, 49, 9, 17, 76, 2888, 27]
assert oracle(str(len(SAMPLE_VALUES)) + "\n" + "\n".join(map(str, SAMPLE_VALUES)) + "\n") == \
    "Yes\nYes\nNo\nNo\nYes\nYes\nYes\nNo\nYes\nNo\n"
assert all(brute(value) for value in (0, 1, 2, 5, 25, 50, 65, 325))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 5, 9, 25, 49, 3 * 3 * 7 * 7,
                      3**3, 7**3, 10**12, 999999937])

    wide = [10**12, 999999999999, 999999000000, 2**39, 3**25,
            650**2, 1000000**2]
    write("3_wide", wide)

    random.seed(2024)
    random_values = [random.randint(0, 10**12) for _ in range(100)]
    write("4_random", random_values)

    io_values = [random.randint(0, 10**12) for _ in range(1000)]
    write("5_io", io_values)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_VALUES)
build()
