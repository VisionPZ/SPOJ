#!/usr/bin/env python3
import random
from decimal import Decimal, getcontext
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
getcontext().prec = 120
PHI = (Decimal(1) + Decimal(5).sqrt()) / Decimal(2)


def lucas_matrix(exponent):
    current = (1, 1, 1, 0)
    result = (1, 0, 0, 1)
    base = exponent
    while base > 0:
        if base & 1:
            a, b, c, d = result
            e, f, g, h = current
            result = ((a * e + b * g) % MOD, (a * f + b * h) % MOD,
                      (c * e + d * g) % MOD, (c * f + d * h) % MOD)
        a, b, c, d = current
        current = ((a * a + b * c) % MOD, (a * b + b * d) % MOD,
                   (c * a + d * c) % MOD, (c * b + d * d) % MOD)
        base >>= 1
    return (result[0] + result[3]) % MOD


def oracle(text):
    values = [int(value) for value in text.split()]
    answers = []
    for exponent in values[1:]:
        if exponent in (0, 1):
            answers.append(exponent + 1)
        else:
            answers.append(lucas_matrix(exponent))
    return "".join(str(value) + "\n" for value in answers)


SAMPLE = "2\n1\n3\n"
SAMPLE_OUT = "2\n4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert int((PHI ** 1).to_integral_value()) == 2
assert int((PHI ** 3).to_integral_value()) == 4
for exponent in range(0, 201):
    matrix_value = oracle(f"1\n{exponent}\n").strip()
    exact_value = int((PHI ** exponent).to_integral_value())
    assert int(matrix_value) == exact_value % MOD, exponent


def write(name, exponents):
    text = f"{len(exponents)}\n" + "".join(str(value) + "\n" for value in exponents)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 5, 10, 50, 100])
    write("3_wide", [10 ** 9, 999999999, 123456789, 2, 7])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 10 ** 9) for _ in range(100)])
    write("5_io", [rng.randint(0, 10 ** 9) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
