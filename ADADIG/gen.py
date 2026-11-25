#!/usr/bin/env python3
import random
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10 ** 9 + 7


def oracle_answer(target):
    total = 0

    def walk(remaining, digit_sum, length):
        nonlocal total
        if remaining == 1:
            ones = target - digit_sum
            if ones >= 0:
                total = (total + comb(ones + length, length)) % MOD
            return
        for digit in range(2, 10):
            if remaining % digit == 0:
                walk(remaining // digit, digit_sum + digit, length + 1)

    walk(target, 0, 0)
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = [str(oracle_answer(tokens[index])) for index in range(1, case_count + 1)]
    return "\n".join(answers) + "\n"


SAMPLE = """8
1
2
3
7
8
12
16
144
"""
SAMPLE_OUT = """1
1
1
1
23
240
1091
243368058
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_answer(4) == 2
assert oracle_answer(6) == 7
assert oracle_answer(9) == 11
assert oracle_answer(999983) == 0


def write(name, targets):
    text = str(len(targets)) + "\n" + "".join(f"{target}\n" for target in targets)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 6, 9, 10, 12, 999983])
    write("3_wide", [300000, 299999, 262144, 279936, 277200, 233280])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 300000) for _ in range(40)])
    write("5_io", [rng.randint(1, 3000) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
