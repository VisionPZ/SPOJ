#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    first_base = int(tokens[1])
    second_base = int(tokens[2])
    cursor = 3
    results = []
    for _ in range(case_count):
        digit_count = int(tokens[cursor])
        cursor += 1
        digits = [int(value) for value in tokens[cursor:cursor + digit_count]]
        cursor += digit_count
        value = 0
        for exponent, digit in enumerate(digits):
            value += digit * first_base ** exponent
        converted = []
        while value > 0:
            value, remainder = divmod(value, second_base)
            converted.append(remainder)
        results.append(str(len(converted)))
        results.append(" ".join(str(digit) for digit in converted))
    return "\n".join(results) + "\n"


SAMPLE = """1 10 100
5
5 4 3 2 1
"""
SAMPLE_OUT = """3
45 23 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 2 10\n1\n1\n2\n0 1\n2\n1 1\n") == "1\n1\n1\n2\n1\n3\n"
assert oracle("1 10 10\n3\n5 4 3\n") == "3\n5 4 3\n"
assert oracle("1 10 16\n2\n6 1\n") == "2\n0 1\n"
assert 12345 == sum(digit * 10 ** index for index, digit in enumerate([5, 4, 3, 2, 1]))


def write_cases(name, first_base, second_base, cases):
    lines = ["%d %d %d" % (len(cases), first_base, second_base)]
    for digits in cases:
        lines.append(str(len(digits)))
        lines.append(" ".join(str(digit) for digit in digits))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def random_digits(rng, base, length):
    digits = [rng.randrange(base) for _ in range(length)]
    digits[-1] = rng.randrange(1, base)
    return digits


def build():
    write_cases("2_edges", 2, 10, [[1], [0, 1], [1, 1], [0, 0, 1]])
    rng = random.Random(20261126)
    write_cases("3_wide", 1000000000, 999999937, [random_digits(rng, 1000000000, 1000)])
    write_cases("4_random", 1000003, 2, [random_digits(rng, 1000003, rng.randint(1, 100)) for _ in range(10)])
    write_cases("5_io", 2, 2, [random_digits(rng, 2, 4000) for _ in range(50)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
