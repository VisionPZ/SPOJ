#!/usr/bin/env python3
import heapq
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def factorize(number):
    factors = []
    divisor = 2
    while divisor * divisor <= number:
        if number % divisor == 0:
            exponent = 0
            while number % divisor == 0:
                number //= divisor
                exponent += 1
            factors.append((divisor, exponent))
        divisor += 1
    if number > 1:
        factors.append((number, 1))
    return factors


def multiply_pair(left, right):
    return (left[0] * right[0] + 2 * left[1] * right[1],
            left[1] * right[0] + left[0] * right[1])


def prime_representation(prime):
    coefficient = 1
    while 2 * coefficient * coefficient <= 2 * prime + 4:
        upper = 2 * coefficient * coefficient + prime
        root = math.isqrt(upper)
        if root * root == upper:
            return (root, coefficient)
        lower = 2 * coefficient * coefficient - prime
        if lower > 0:
            root = math.isqrt(lower)
            if root * root == lower:
                return (root, coefficient)
        coefficient += 1
    raise ValueError(prime)


def orbit_bases(factors, difference):
    choices = [(1, 1)]
    for prime, exponent in factors:
        if prime == 2:
            for _ in range(2 * exponent):
                choices = [multiply_pair(base, (0, 1)) for base in choices]
        elif prime % 8 in (3, 5):
            for _ in range(exponent):
                choices = [multiply_pair(base, (prime, 0)) for base in choices]
        else:
            first, second = prime_representation(prime)
            positive = [(1, 0)]
            negative = [(1, 0)]
            for _ in range(2 * exponent):
                positive.append(multiply_pair(positive[-1], (first, second)))
                negative.append(multiply_pair(negative[-1], (first, -second)))
            expanded = []
            for base in choices:
                for split in range(2 * exponent + 1):
                    part = multiply_pair(base, positive[split])
                    expanded.append(multiply_pair(part, negative[2 * exponent - split]))
            choices = expanded
    bases = []
    for choice in choices:
        for sign in (1, -1):
            real, imaginary = sign * choice[0], sign * choice[1]
            found = False
            for _ in range(200):
                if real > difference and imaginary > 0:
                    found = True
                    break
                real, imaginary = 3 * real + 4 * imaginary, 2 * real + 3 * imaginary
            if not found:
                continue
            for _ in range(200):
                previous_real = 3 * real - 4 * imaginary
                previous_imaginary = 3 * imaginary - 2 * real
                if previous_real > difference and previous_imaginary > 0:
                    real, imaginary = previous_real, previous_imaginary
                else:
                    break
            if (real, imaginary) not in bases:
                bases.append((real, imaginary))
    return bases


def oracle_case(index, difference, modulus, factors):
    bases = orbit_bases(factors, difference)
    streams = []
    for real, imaginary in bases:
        def generator(current_real, current_imaginary):
            while True:
                yield current_imaginary, current_real
                current_real, current_imaginary = (3 * current_real + 4 * current_imaginary,
                                                   2 * current_real + 3 * current_imaginary)
        streams.append(generator(real, imaginary))
    answer = None
    for counter, (hypotenuse, double_value) in enumerate(heapq.merge(*streams, key=lambda pair: pair[0]), 1):
        if counter == index:
            first_leg = (double_value - difference) // 2
            answer = f"{first_leg % modulus} {(first_leg + difference) % modulus} {hypotenuse % modulus}\n"
            break
    if answer is None:
        raise ValueError("index too large")
    return answer


def oracle(text):
    tokens = list(map(int, text.split()))
    count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(count):
        index = tokens[cursor]
        difference = tokens[cursor + 1]
        modulus = tokens[cursor + 2]
        length = tokens[cursor + 3]
        cursor += 4
        factors = []
        for _ in range(length):
            factors.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        answers.append(oracle_case(index, difference, modulus, factors))
    return "".join(answers)


SAMPLE = """3
1 1 235813
0
3 21 1000
2 3 1 7 1
9 119 11
2 7 1 17 1
"""
SAMPLE_OUT = """3 4 5
63 84 105
5 3 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 7 1000\n1 7 1\n") == "5 12 13\n"
assert oracle("1\n6 21 1000\n2 3 1 7 1\n") == "420 441 609\n"
assert oracle("1\n1 1 100\n0\n") == "3 4 5\n"
assert factorize(119) == [(7, 1), (17, 1)]


def write(name, cases):
    lines = [str(len(cases))]
    for index, difference, modulus, factors in cases:
        lines.append(f"{index} {difference} {modulus}")
        lines.append(str(len(factors)) + " " + " ".join(f"{prime} {exponent}" for prime, exponent in factors))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    differences = [1, 7, 21, 35, 119, 221, 255, 2023, 2737, 1000003]
    wide = []
    for difference in differences:
        factors = factorize(difference)
        for index in (1, 7, 13, 20, 100, 500):
            wide.append((index, difference, 1000000000, factors))
    write("3_wide", wide)
    rng = random.Random(20261202)
    random_cases = []
    for _ in range(40):
        difference = rng.choice(differences)
        index = rng.randint(1, 300)
        random_cases.append((index, difference, rng.randint(2, 1000000000), factorize(difference)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(500):
        difference = rng.choice(differences)
        index = rng.randint(1, 400)
        io_cases.append((index, difference, rng.randint(2, 1000000000), factorize(difference)))
    write("5_io", io_cases)
    write("2_edges", [(1, 1, 235813, []), (3, 21, 1000, [(3, 1), (7, 1)]),
                      (9, 119, 11, [(7, 1), (17, 1)]), (1, 1000003, 97, [(1000003, 1)])])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
