#!/usr/bin/env python3
import random
from math import isqrt
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_N = 12148001999


def triangle(value):
    return value * (value + 1) // 2


def oracle(text):
    values = [int(value) for value in text.split()]
    answers = []
    for limit in values[1:]:
        root = isqrt(limit)
        total = sum(divisor * (limit // divisor) for divisor in range(1, root + 1))
        total += sum(triangle(limit // quotient) - triangle(root)
                     for quotient in range(1, root + 1))
        answers.append(total - triangle(limit))
    return "".join(str(value) + "\n" for value in answers)


def brute(limit):
    sequence = [0] * (limit + 1)
    for value in range(2, limit + 1):
        proper = sum(divisor for divisor in range(1, value) if value % divisor == 0)
        sequence[value] = sequence[value - 1] + proper
    return sequence


SAMPLE = "3\n3\n4\n5\n"
SAMPLE_OUT = "2\n5\n6\n"
assert oracle(SAMPLE) == SAMPLE_OUT
small = brute(120)
assert all(int(oracle(f"1\n{n}\n")) == small[n] for n in range(0, 121))
assert oracle("1\n1\n") == "0\n"
assert oracle("1\n12148001999\n").strip() == "47587734680382878674"


def write(name, values):
    text = f"{len(values)}\n" + "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100])
    write("3_wide", [MAX_N, MAX_N - 1, 12148001998, 12148001997])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, MAX_N) for _ in range(100)])
    write("5_io", [MAX_N - rng.randint(0, 1000000) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
