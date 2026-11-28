#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    left_text, right_text = text.split()[:2]
    left_digits = list(reversed(left_text))
    right_digits = list(reversed(right_text))
    carry = 0
    result_digits = []
    limit = max(len(left_digits), len(right_digits))
    for index in range(limit):
        total = carry
        if index < len(left_digits):
            total += ord(left_digits[index]) - 48
        if index < len(right_digits):
            total += ord(right_digits[index]) - 48
        result_digits.append(chr(48 + total % 10))
        carry = total // 10
    if carry:
        result_digits.append(chr(48 + carry))
    while len(result_digits) > 1 and result_digits[-1] == '0':
        result_digits.pop()
    return ''.join(reversed(result_digits)) + "\n"


SAMPLE = "10 35\n"
SAMPLE_OUT = "45\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0 0\n") == "0\n"
assert oracle("999 1\n") == "1000\n"
assert oracle("1000000000000 999999999999\n") == "1999999999999\n"
assert 10 + 35 == 45


def write(name, left, right):
    text = f"{left} {right}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 0, 0)
    write("3_wide", 999999999999, 1)
    rng = random.Random(20261125)
    write("4_random", rng.randint(0, 10**12), rng.randint(0, 10**12))
    write("5_io", 999999999999999, 999999999999999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 10, 35)
build()
