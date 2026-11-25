#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 29
PERIOD = 28
PRIME_BASES = [2, 3, 167]


def prefix_sums(prime_base):
    residue = prime_base % MODULUS
    powers = [1]
    for _ in range(PERIOD - 1):
        powers.append(powers[-1] * residue % MODULUS)
    prefix = [0]
    for value in powers:
        prefix.append((prefix[-1] + value) % MODULUS)
    return prefix


PREFIX_TABLES = [prefix_sums(prime_base) for prime_base in PRIME_BASES]


def geometric_sum(prime_index, exponent_count):
    return PREFIX_TABLES[prime_index][(exponent_count + 1) % PERIOD]


def oracle(text):
    answers = []
    for token in text.split():
        exponent_value = int(token)
        if exponent_value == 0:
            break
        product = 1
        for prime_index in range(len(PRIME_BASES)):
            exponent_count = exponent_value * 2 if prime_index == 0 else exponent_value
            factor = geometric_sum(prime_index, exponent_count)
            product = product * factor % MODULUS
        answers.append(str(product))
    return "\n".join(answers) + "\n"


def brute(exponent_value):
    total = 0
    for power_two in range(2 * exponent_value + 1):
        for power_three in range(exponent_value + 1):
            for power_167 in range(exponent_value + 1):
                term = pow(2, power_two) * pow(3, power_three) * pow(167, power_167)
                total = (total + term) % MODULUS
    return total


SAMPLE = "1\n10000\n0\n"
SAMPLE_OUT = "6\n10\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n0\n") == str(brute(2)) + "\n"
assert oracle("3\n4\n0\n") == f"{brute(3)}\n{brute(4)}\n"
assert geometric_sum(0, 2) == 7
assert geometric_sum(1, 1) == 4
assert geometric_sum(2, 1) == 23


def write(name, exponents):
    text = "\n".join(str(value) for value in exponents) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 0])
    write("3_wide", [10000000, 9999999, 5000001, 28, 29, 30, 0])
    rng = random.Random(20261126)
    values = [rng.randint(1, 10000000) for _ in range(200)] + [0]
    write("4_random", values)
    values = [rng.randint(1, 10000000) for _ in range(20000)] + [0]
    write("5_io", values)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
