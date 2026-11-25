#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def digits_in_base(age, base):
    digits = []
    while age > 0:
        digit = age % base
        if digit > 9:
            return None
        digits.append(digit)
        age //= base
    digits.reverse()
    return digits


def works(age, base, lower):
    digits = digits_in_base(age, base)
    if digits is None:
        return False
    decimal = 0
    for digit in digits:
        decimal = decimal * 10 + digit
    return decimal >= lower


def oracle(age, lower):
    best = 10
    cap = min(age, 200000)
    for base in range(2, cap + 1):
        if works(age, base, lower):
            best = base
    for unit in range(0, 10):
        for tens in range(1, 10):
            if (age - unit) % tens == 0:
                base = (age - unit) // tens
                if base > cap and base > tens and base > unit:
                    if works(age, base, lower):
                        best = max(best, base)
    for hundreds in range(1, 10):
        for tens in range(0, 10):
            for unit in range(0, 10):
                approx = math.isqrt(age // hundreds)
                for base in range(max(2, approx - 2), approx + 3):
                    if base > cap and works(age, base, lower):
                        best = max(best, base)
    for leading in range(1, 10):
        approx = int(round((age // leading) ** (1.0 / 3.0)))
        for base in range(max(2, approx - 5), approx + 6):
            if base > cap and works(age, base, lower):
                best = max(best, base)
    return best


SAMPLE = """32 20
2016 100
"""
SAMPLE_OUT = """16
42
"""
def oracle_text(text):
    answers = []
    for line in text.strip().splitlines():
        age, lower = (int(value) for value in line.split())
        answers.append(str(oracle(age, lower)))
    return "\n".join(answers) + "\n"


assert oracle(32, 20) == 16
assert oracle(2016, 100) == 42
assert oracle_text(SAMPLE) == SAMPLE_OUT
assert oracle(10, 10) == 10
assert oracle(100, 100) == 10
assert oracle(2016, 10) == 2016


def write(name, cases):
    text = "\n".join(f"{age} {lower}" for age, lower in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(
        "\n".join(str(oracle(age, lower)) for age, lower in cases) + "\n"
    )


def build():
    write("2_edges", [(10, 10), (11, 10), (99, 10), (100, 99), (1000, 10)])
    write("3_wide", [(10**18, 10**18), (10**18, 999), (999999999999, 10)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(12):
        age = rng.randint(10, 10**9)
        lower = rng.randint(10, min(age, 5000))
        random_cases.append((age, lower))
    write("4_random", random_cases)
    rng = random.Random(20261127)
    io_cases = [(rng.randint(10, 20000), rng.randint(10, 500)) for _ in range(30)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(32, 20), (2016, 100)])
build()
