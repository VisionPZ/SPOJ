#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SMALL_PRIMES = [2, 3, 5, 7, 11, 13, 17, 1009, 10007, 100003, 1000003, 999999937, 1000000007]


def smallest_factor_table(limit):
    table = list(range(limit + 1))
    for factor in range(2, int(limit ** 0.5) + 1):
        if table[factor] == factor:
            for multiple in range(factor * factor, limit + 1, factor):
                if table[multiple] == multiple:
                    table[multiple] = factor
    return table


def consecutive_representations(value):
    ways = 0
    for length in range(2, value + 1):
        doubled = 2 * value
        if doubled % length:
            continue
        start_times_two = doubled // length - length + 1
        if start_times_two > 0 and start_times_two % 2 == 0:
            ways += 1
    return ways


def oracle(cases):
    largest = max((number for number, _ in cases), default=1)
    factors = smallest_factor_table(largest)
    exponents = {}
    answers = []
    previous = 1
    for number, modulus in sorted(cases, key=lambda item: item[0]):
        for value in range(previous + 1, number + 1):
            remainder = value
            while remainder > 1:
                prime = factors[remainder]
                power = 0
                while remainder % prime == 0:
                    remainder //= prime
                    power += 1
                exponents[prime] = exponents.get(prime, 0) + power
        previous = number
        product = 1
        for prime, exponent in exponents.items():
            if prime != 2:
                product = product * (exponent + 1) % modulus
        answers.append((number, modulus, (product - 1) % modulus))
    by_key = {(number, modulus): answer for number, modulus, answer in answers}
    return "".join(str(by_key[(number, modulus)]) + "\n" for number, modulus in cases)


SAMPLE = "1\n3 7\n"
SAMPLE_OUT = "1\n"
assert oracle([(3, 7)]) == SAMPLE_OUT
assert oracle([(1, 7), (2, 7), (3, 7), (4, 7), (5, 7)]) == "0\n0\n1\n1\n3\n"
assert oracle([(3, 2), (4, 3), (5, 11)]) == "1\n1\n3\n"
assert oracle([(9, 10**9 + 7)]) == "19\n"
def odd_divisor_count(value):
    while value % 2 == 0:
        value //= 2
    count = 1
    factor = 3
    while factor * factor <= value:
        power = 0
        while value % factor == 0:
            value //= factor
            power += 1
        count *= power + 1
        factor += 2
    if value > 1:
        count *= 2
    return count


for value in range(1, 300):
    assert consecutive_representations(value) == odd_divisor_count(value) - 1
for factorial_index in range(1, 8):
    factorial_value = math.factorial(factorial_index)
    assert oracle([(factorial_index, 10**9 + 7)]) == str(consecutive_representations(factorial_value)) + "\n"


def write(name, cases):
    text = str(len(cases)) + "".join(f"\n{number} {modulus}" for number, modulus in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def build():
    write("2_edges", [(1, 7), (2, 7), (3, 7), (4, 7), (5, 7), (6, 7),
                      (1, 2), (3, 2), (4, 3), (9, 1000000007)])
    write("3_wide", [(20000, modulus) for modulus in SMALL_PRIMES])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 5000), rng.choice(SMALL_PRIMES)) for _ in range(100)])
    write("5_io", [(rng.randint(1, 20000), rng.choice(SMALL_PRIMES)) for _ in range(500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 7)])
build()
