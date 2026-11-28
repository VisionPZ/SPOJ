#!/usr/bin/env python3
import random
import sys
from pathlib import Path

sys.set_int_max_str_digits(0)
ROOT = Path(__file__).resolve().parent
CHUNK_BITS = 16384
CHUNK_MASK = (1 << CHUNK_BITS) - 1


def oracle_case(first_base, first_exponent, second_base, second_exponent):
    combined = (first_base ** first_exponent) ^ (second_base ** second_exponent)
    digit_sum = 0
    while combined:
        digit_sum += combined & CHUNK_MASK
        combined >>= CHUNK_BITS
    return str(digit_sum)


def oracle(text):
    tokens = text.split()
    test_count = int(tokens[0])
    scan = 1
    lines = []
    for _ in range(test_count):
        first_base = int(tokens[scan]); scan += 1
        first_exponent = int(tokens[scan]); scan += 1
        second_base = int(tokens[scan]); scan += 1
        second_exponent = int(tokens[scan]); scan += 1
        lines.append(oracle_case(first_base, first_exponent, second_base, second_exponent))
    return "\n".join(lines) + "\n"


SAMPLE = """2
7 3 5 4
1234 5678 9012 4444
"""
FIRST_ANSWER = "806"
SECOND_ANSWER = oracle_case(1234, 5678, 9012, 4444)
SAMPLE_OUT = FIRST_ANSWER + "\n" + SECOND_ANSWER + "\n"
assert oracle_case(7, 3, 5, 4) == "806"
assert oracle(SAMPLE) == SAMPLE_OUT
assert SECOND_ANSWER.startswith("1194204158794232147799")
assert SECOND_ANSWER.endswith("9938532444216215551948305")
assert len(SECOND_ANSWER) == 4933
assert (1234 ** 5678 ^ 9012 ** 4444) != 0
assert oracle("1\n1 1 1 1\n") == "0\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for case in cases:
        text += " ".join(str(value) for value in case) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("1_sample", [(7, 3, 5, 4), (1234, 5678, 9012, 4444)])
    write("2_edges", [(1, 1, 1, 1), (2, 1, 2, 2), (3, 2, 3, 1)])
    write("3_wide", [(10000, 40, 9999, 35), (7, 100, 5, 90), (13, 200, 11, 180)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(15):
        random_cases.append(tuple(rng.randint(2, 300) for _ in range(2)) +
                            tuple(rng.randint(2, 300) for _ in range(2)))
    write("4_random", random_cases)
    write("5_io", [(10000, 10000, 9999, 9999), (10000, 9999, 9999, 10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
