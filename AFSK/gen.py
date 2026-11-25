#!/usr/bin/env python3
import random
from fractions import Fraction
from math import lcm
from pathlib import Path

ROOT = Path(__file__).resolve().parent
polynomials = {}


def power_polynomial(power):
    if power in polynomials:
        return polynomials[power]
    points = list(range(power + 2))
    values = [sum(pow(value, power) for value in range(point + 1))
              for point in points]
    coefficients = [Fraction(0)] * (power + 2)
    for point, value in zip(points, values):
        basis = [Fraction(1)]
        for other in points:
            if other == point:
                continue
            expanded = [Fraction(0)] * (len(basis) + 1)
            for degree, coefficient in enumerate(basis):
                expanded[degree] -= other * coefficient
                expanded[degree + 1] += coefficient
            basis = expanded
            scale = sum(coefficient * point ** degree
                        for degree, coefficient in enumerate(basis))
            assert scale != 0
            basis = [coefficient / scale for coefficient in basis]
        coefficients = [left + value * right
                        for left, right in zip(coefficients, basis)]
    denominator = 1
    for coefficient in coefficients:
        denominator = lcm(denominator, coefficient.denominator)
    scaled = [int(coefficient * denominator) for coefficient in coefficients]
    polynomials[power] = (scaled, denominator)
    return polynomials[power]


def power_sum(limit, power):
    scaled, denominator = power_polynomial(power)
    total = 0
    current = 1
    for coefficient in scaled:
        total += coefficient * current
        current *= limit
    assert total % denominator == 0
    return total // denominator


def sequence_value(limit, power, modulus):
    answer = 0
    left = 1
    while left <= limit:
        quotient = limit // left
        right = limit // quotient
        block = power_sum(right, power) - power_sum(left - 1, power)
        answer = (answer + (block % modulus) * (quotient % modulus)) % modulus
        left = right + 1
    return answer


def oracle(text):
    tokens = [int(value) for value in text.split()]
    answers = []
    position = 1
    for _ in range(tokens[0]):
        limit, power, modulus = tokens[position:position + 3]
        position += 3
        answers.append(sequence_value(limit, power, modulus))
    return "".join(str(value) + "\n" for value in answers)


def brute(limit, power):
    total = 0
    for multiple in range(1, limit + 1):
        for divisor in range(1, multiple + 1):
            if multiple % divisor == 0:
                total += pow(divisor, power)
    return total


SAMPLE = "3\n3 1 10\n4 2 55\n5 3 97\n"
SAMPLE_OUT = "8\n37\n43\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(5, 3) == 237
assert all(power_sum(limit, power) == sum(pow(value, power)
                                          for value in range(limit + 1))
           for power in range(1, 6) for limit in range(30))
assert all(sequence_value(limit, power, 1000000007) == brute(limit, power) % 1000000007
           for limit in range(1, 41) for power in range(1, 4))


def write(name, rows):
    text = f"{len(rows)}\n" + "".join(f"{limit} {power} {modulus}\n"
                                      for limit, power, modulus in rows)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 2), (2, 10, 3), (3, 2, 4), (10, 3, 100),
                      (100, 5, 1000000007), (1000, 10, 99999999999999999)])
    write("3_wide", [(10 ** 9, 1, 99999999999999999),
                     (999999999, 5, 1000000007),
                     (1000000000 - 1, 10, 99999999999999999)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 2000), rng.randint(1, 10),
                        rng.randint(2, 10 ** 17 - 1)) for _ in range(100)])
    write("5_io", [(rng.randint(1, 2000), rng.randint(1, 10),
                    rng.randint(10 ** 17 - 1000, 10 ** 17 - 1))
                   for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
