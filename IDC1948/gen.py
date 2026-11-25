#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def distance_to_repunit(number):
    digits = len(str(number))
    candidate = int("9" * digits)
    if candidate <= number:
        candidate = int("9" * (digits + 1))
    return candidate - number


def oracle(text):
    values = [int(token) for token in text.split()]
    answers = []
    for number in values[1:]:
        gap = distance_to_repunit(number)
        difference = abs(gap - number)
        if difference <= 1:
            answers.append("-1")
            continue
        found = difference
        for divisor in range(2, min(difference, 100000) + 1):
            if gap % divisor == number % divisor:
                found = divisor
                break
        answers.append(str(found))
    return "\n".join(answers) + "\n"


SAMPLE = """2
234
5
"""
SAMPLE_OUT = """3
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "7\n"
assert oracle("1\n45\n") == "3\n"
assert oracle("1\n100\n") == "17\n"
assert distance_to_repunit(99) == 900


def write(name, values):
    text = str(len(values)) + "\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 5, 9, 45, 100])
    write("3_wide", [29999999, 29999998, 12345678, 10000001, 20000000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 29999999) for _ in range(15)])
    write("5_io", [rng.randint(1, 29999999) for _ in range(19)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [234, 5])
build()
