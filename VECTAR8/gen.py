#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_N = 999999


def build_prefix(limit):
    sieve = bytearray([1]) * (limit + 1)
    sieve[0] = 0
    sieve[1] = 0
    for value in range(2, math.isqrt(limit) + 1):
        if sieve[value]:
            sieve[value * value::value] = b"\0" * len(sieve[value * value::value])
    prefix = [0] * (limit + 1)
    for number in range(2, limit + 1):
        digits = str(number)
        scary = bool(sieve[number]) and "0" not in digits
        if scary:
            for start in range(1, len(digits)):
                if not sieve[int(digits[start:])]:
                    scary = False
                    break
        prefix[number] = prefix[number - 1] + (1 if scary else 0)
    return prefix


PREFIX = build_prefix(MAX_N)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for index in range(case_count):
        answers.append(str(PREFIX[tokens[index + 1]]))
    return "\n".join(answers) + "\n"


SAMPLE = """3
2
3
4
"""
SAMPLE_OUT = """1
2
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5\n20 50 100 1000 155\n") == "6\n10\n15\n54\n17\n"
assert oracle("1\n1\n") == "0\n"
assert oracle("1\n999999\n") == str(PREFIX[999999]) + "\n"
assert PREFIX[1000] == 54


def write(name, bounds):
    text = str(len(bounds)) + "\n" + "".join(str(value) + "\n" for value in bounds)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 10, 20, 50, 100, 155, 1000, 999999])
    write("3_wide", [999999, 999998, 999990, 500000, 999000, 123456])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, MAX_N) for _ in range(200)])
    write("5_io", [rng.randint(1, MAX_N) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 3, 4])
build()
