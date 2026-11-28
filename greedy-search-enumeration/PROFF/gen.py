#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def format_answer(carries):
    if carries == 0:
        return "No carry operation.\n"
    if carries == 1:
        return "1 carry operation.\n"
    return f"{carries} carry operations.\n"


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    results = []
    for line in lines:
        left_text, right_text = line.split()
        left_digits = list(reversed(left_text))
        right_digits = list(reversed(right_text))
        carry = 0
        carries = 0
        for position in range(max(len(left_digits), len(right_digits))):
            left_digit = int(left_digits[position]) if position < len(left_digits) else 0
            right_digit = int(right_digits[position]) if position < len(right_digits) else 0
            if left_digit + right_digit + carry >= 10:
                carries += 1
                carry = 1
            else:
                carry = 0
        if int(left_text) == 0 and int(right_text) == 0:
            break
        results.append(format_answer(carries))
    return "".join(results)


SAMPLE = """123 456
555 555
123 594
0 0
"""
SAMPLE_OUT = """No carry operation.
3 carry operations.
1 carry operation.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("123 594\n0 0\n") == "1 carry operation.\n"
assert oracle("5 0\n0 999\n1 1\n0 0\n") == "No carry operation.\n" * 3
assert oracle("999999999 1\n0 0\n") == "9 carry operations.\n"
assert oracle("555 555\n0 0\n") == "3 carry operations.\n"


def write(name, pairs):
    text = "".join(f"{left} {right}\n" for left, right in pairs) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(5, 0), (0, 999), (1, 1), (999999999, 0)])
    write("3_wide", [(999999999, 1), (999999999, 999999999),
                     (123456789, 876543211)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(40):
        left = rng.randint(0, 999999999)
        right = rng.randint(0, 999999999)
        pairs.append((left, right))
    write("4_random", pairs)
    pairs = []
    for _ in range(2000):
        left = rng.randint(0, 999999999)
        right = rng.randint(0, 999999999)
        pairs.append((left, right))
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(123, 456), (555, 555), (123, 594)])
build()
