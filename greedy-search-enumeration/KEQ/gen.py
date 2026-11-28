#!/usr/bin/env python3
import random
from math import gcd
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PERIOD_CAP = 200000


def period_length(modulus):
    residue = 1 % modulus
    for length in range(1, PERIOD_CAP + 1):
        residue = residue * 10 % modulus
        if residue == 1 % modulus:
            return length
    return None


def brute_answer(max_digits, divisors):
    for length in range(max_digits, 0, -1):
        repunit = (10 ** length - 1) // 9
        for digit in range(9, 0, -1):
            candidate = digit * repunit
            if any(candidate % divisor == 0 for divisor in divisors):
                return length, digit
    return 1, 0


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        max_digits = tokens[cursor]
        divisor_count = tokens[cursor + 1]
        cursor += 2
        divisors = tokens[cursor:cursor + divisor_count]
        cursor += divisor_count
        if max_digits <= 60:
            best_length, best_digit = brute_answer(max_digits, divisors)
        else:
            best_length, best_digit = 0, 0
            for divisor in divisors:
                for digit in range(1, 10):
                    reduced = divisor // gcd(divisor, digit)
                    if gcd(reduced, 10) != 1:
                        continue
                    length = period_length(9 * reduced)
                    if length is None:
                        continue
                    answer_length = (max_digits // length) * length
                    if answer_length >= 1 and (answer_length, digit) > (best_length, best_digit):
                        best_length, best_digit = answer_length, digit
            if (best_length, best_digit) == (0, 0):
                best_length, best_digit = 1, 0
        answers.append(f"{best_length} {best_digit}")
    return "\n".join(answers) + "\n"


SAMPLE = """3

47 2
42
47

99 4
123
234
345
456

3 1
4700
"""
SAMPLE_OUT = """46 9
96 6
1 0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n1\n") == "1 9\n"
assert oracle("1\n50 1\n4700\n") == "1 0\n"
assert oracle("1\n12 2\n3\n37\n") == "12 9\n"
assert oracle("1\n10 1\n1\n") == "10 9\n"
assert period_length(9) == 1
assert period_length(63) == 6


def write(name, cases):
    parts = [str(len(cases))]
    for max_digits, divisors in cases:
        parts.append(f"{max_digits} {len(divisors)}")
        parts.extend(str(divisor) for divisor in divisors)
    text = "\n\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, [1]),
        (1, [4700]),
        (2, [1]),
        (6, [7]),
        (10, [9999]),
    ])
    write("3_wide", [
        (1000000000, [3, 7, 11, 13, 37, 999999, 100000000000000]),
        (999999999, [9, 99, 999, 9999, 99999, 999999, 100000000000000]),
        (1000000000, [4700, 100000000000000, 999999, 27, 81, 37, 1]),
    ])
    rng = random.Random(20261201)
    write("4_random", [
        (rng.randint(1, 55), [rng.randint(1, 200000) for _ in range(rng.randint(1, 7))])
        for _ in range(20)
    ])
    write("5_io", [
        (rng.randint(1, 45), [rng.randint(1, 100000) for _ in range(rng.randint(1, 7))])
        for _ in range(1000)
    ])
    big_cases = [
        (1000000000, [rng.randint(1, 10 ** 14) for _ in range(7)])
        for _ in range(100)
    ]
    big_parts = [str(len(big_cases))]
    for max_digits, divisors in big_cases:
        big_parts.append(f"{max_digits} 7")
        big_parts.extend(str(divisor) for divisor in divisors)
    Path("/tmp/KEQ_big.txt").write_text("\n\n".join(big_parts) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
