#!/usr/bin/env python3
import itertools
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def divisor_values(number):
    if number == 0:
        return 0, 0
    count = 0
    total = 0
    for divisor in range(1, math.isqrt(number) + 1):
        if number % divisor == 0:
            count += 1
            total += divisor
            partner = number // divisor
            if partner != divisor:
                count += 1
                total += partner
    return count, total


def oracle(text):
    numbers = list(map(int, text.split()))
    answers = []
    pos = 0
    while pos < len(numbers):
        digit_count = numbers[pos]
        pos += 1
        digits = numbers[pos:pos + digit_count]
        pos += digit_count
        best_count = (-1, 0)
        best_sum = (-1, 0)
        for arrangement in set(itertools.permutations(digits)):
            assembled = 0
            for digit in arrangement:
                assembled = assembled * 10 + digit
            count, total = divisor_values(assembled)
            if (count, -assembled) > (best_count[0], -best_count[1]):
                best_count = (count, assembled)
            if (total, -assembled) > (best_sum[0], -best_sum[1]):
                best_sum = (total, assembled)
        answers.append(f"{best_count[1]} {best_sum[1]}")
    return "\n".join(answers) + "\n"


SAMPLE = """1
5
"""
SAMPLE_OUT = """5 5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n1 1 0\n") == "110 110\n"
assert oracle("2\n3 4\n") == "34 34\n"
assert oracle("3\n4 8 2\n") == "248 824\n"
assert oracle("4\n1 3 5 7\n") == "7315 7315\n"
assert oracle("5\n1 2 3 4 5\n") == "43512 51324\n"
assert oracle("6\n2 2 3 3 4 4\n") == "432432 432432\n"
assert oracle("7\n1 2 3 4 5 6 7\n") == "3124576 7516432\n"


def write(name, cases):
    lines = []
    for digits in cases:
        lines.append(str(len(digits)))
        lines.append(" ".join(map(str, digits)))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0], [0, 0], [0, 0, 1], [1, 1, 1], [9, 9]])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(0, 9) for _ in range(6)] for _ in range(30)])
    write("4_random", [[rng.randint(0, 9) for _ in range(rng.randint(2, 6))] for _ in range(60)])
    write("5_io", [[rng.randint(0, 9) for _ in range(3)] for _ in range(22000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[5]])
build()

stress = "9\n1 2 3 4 5 6 7 8 9\n"
Path("/tmp/ADADIGIT_big.txt").write_text(stress)
