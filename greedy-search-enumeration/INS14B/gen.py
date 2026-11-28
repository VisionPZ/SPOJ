#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for side in tokens[1:1 + case_count]:
        square_area = side * side
        even_divisors = 0
        for divisor in range(2, square_area + 1, 2):
            if square_area % divisor == 0:
                even_divisors += 1
        answers.append(str(even_divisors))
    return "\n".join(answers) + "\n"


def oracle_single(side):
    return oracle("1\n%d\n" % side).strip()


SAMPLE = """2
1
2
"""
SAMPLE_OUT = """0
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_single(1) == "0"
assert oracle_single(2) == "2"
assert oracle_single(4) == "4"
assert oracle_single(3) == "0"
assert oracle_single(12) == "12"


def write_cases(name, sides):
    text = str(len(sides)) + "\n" + "\n".join(str(side) for side in sides) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    write_cases("2_edges", [1, 2, 3, 4, 5, 7, 8, 9, 16])
    write_cases("3_wide", [1000, 999, 512, 840, 997, 729, 1000])
    rng = random.Random(20261126)
    write_cases("4_random", [rng.randint(1, 1000) for _ in range(200)])
    write_cases("5_io", [rng.randint(1, 1000) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
