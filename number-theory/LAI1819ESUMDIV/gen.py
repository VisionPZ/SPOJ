#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2\n2\n2\n2\n2\n"
SAMPLE_OUT = "5.0\n"


def decimal_form(numerator, denominator):
    sign = "-" if numerator < 0 else ""
    value = abs(numerator)
    whole, rest = divmod(value, denominator)
    digit = rest * (10 // denominator)
    return "%s%d.%d" % (sign, whole, digit)


def oracle(input_text):
    tokens = input_text.split()
    answers = []
    scanPos = 0
    while scanPos < len(tokens):
        group = tokens[scanPos:scanPos + 5]
        scanPos += 5
        total = 0
        for token in group:
            total += int(token)
        if total % 2 == 0:
            answers.append(decimal_form(total, 2))
        else:
            answers.append(decimal_form(total, 5))
    if answers:
        return "\n".join(answers) + "\n"
    return ""


def five_case(numbers):
    return "".join("%d\n" % number for number in numbers)


def write(name, cases):
    input_text = "".join(five_case(case) for case in cases)
    (ROOT / "in" / ("%s.txt" % name)).write_text(input_text)
    (ROOT / "out" / ("%s.out" % name)).write_text(oracle(input_text))


SAMPLE = [(2, 2, 2, 2, 2)]

assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1\n1\n1\n1\n") == "1.0\n"
assert oracle("1\n2\n4\n6\n8\n") == "4.2\n"
assert oracle("0\n0\n0\n0\n0\n") == "0.0\n"
assert oracle("1\n1\n1\n1\n2\n") == "3.0\n"
assert oracle("1\n1\n1\n1\n1\n2\n2\n2\n2\n2\n") == "1.0\n5.0\n"


def build():
    write("2_edges", [
        (0, 0, 0, 0, 0), (1, 1, 1, 1, 1), (1, 2, 4, 6, 8),
        (1, 1, 1, 1, 2), (2, 2, 2, 2, 3), (5, 5, 5, 5, 5),
        (1, 2, 3, 4, 5), (10, 10, 10, 10, 10), (1, 1, 1, 1, 3),
    ])
    write("3_wide", [
        (1000000000, 1000000000, 1000000000, 1000000000, 1000000000),
        (999999999, 999999999, 999999999, 999999999, 999999999),
        (1, 1, 1, 1, 999999998),
        (999999999, 999999999, 999999999, 999999999, 1),
    ])
    rng = random.Random(1819)
    random_cases = []
    for _ in range(200):
        random_cases.append(tuple(rng.randint(0, 1000000) for _ in range(5)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(200):
        io_cases.append(tuple(rng.randint(0, 10**9) for _ in range(5)))
    write("5_io", io_cases)


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", SAMPLE)
    build()
