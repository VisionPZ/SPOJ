#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    total = sum(int(value) for value in text.split())
    fuel = Fraction(0)
    extra = Fraction(total, 4)
    tiny = Fraction(1, 10 ** 30)
    while extra > tiny:
        fuel += extra
        extra /= 4
    answer = (fuel.numerator + fuel.denominator - 1) // fuel.denominator
    return str(answer) + "\n"


SAMPLE = """5 5
"""
SAMPLE_OUT = """4
"""
SECOND_SAMPLE = """1255
234
12555
45322342
32
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND_SAMPLE) == "15112140\n"
assert oracle("4\n") == "2\n"
assert oracle("1\n") == "1\n"
assert oracle("0\n") == "0\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1\n0\n3\n")
    write("3_wide", SECOND_SAMPLE)
    rng = random.Random(20261126)
    weights = [str(rng.randint(1, 10 ** 9)) for _ in range(50)]
    write("4_random", "\n".join(weights) + "\n")
    large = [str(10 ** 9) for _ in range(99)]
    write("5_io", "\n".join(large) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
