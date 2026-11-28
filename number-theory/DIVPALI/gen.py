#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def numeric_palindrome(value):
    original = value
    reversed_value = 0
    while value > 0:
        reversed_value = reversed_value * 10 + value % 10
        value //= 10
    return reversed_value == original


def oracle(text):
    number = int(text.split()[0])
    factors = {}
    remaining = number
    candidate = 2
    while candidate * candidate <= remaining:
        while remaining % candidate == 0:
            factors[candidate] = factors.get(candidate, 0) + 1
            remaining //= candidate
        candidate += 1
    if remaining > 1:
        factors[remaining] = 1
    divisors = [1]
    for prime, exponent in factors.items():
        divisors = [divisor * prime ** power
                    for divisor in divisors
                    for power in range(exponent + 1)]
    matches = sorted(divisor for divisor in divisors if numeric_palindrome(divisor))
    return ",".join(str(value) for value in matches) + "\n"


SAMPLE = """121
"""
SAMPLE_OUT = """1,11,121
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("66\n") == "1,2,3,6,11,22,33,66\n"
assert oracle("1\n") == "1\n"
assert oracle("10\n") == "1,2,5\n"
assert oracle("999999999\n") == "1,3,9,111,333,999,1001001,3003003,9009009,111111111,333333333,999999999\n"
assert len(oracle("73513440\n").strip().split(",")) == 36
assert numeric_palindrome(14641) and not numeric_palindrome(14643)


def write(name, number):
    text = str(number) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 999999999)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 1000000000))
    write("5_io", 73513440)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 121)
build()
