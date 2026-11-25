#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def prime_factors(number):
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


def increasing_index(prime, exponent):
    if exponent == 1:
        return prime
    factorial_valuation = 0
    total_valuation = 0
    index = 1
    while total_valuation < exponent:
        remainder = index
        while remainder % prime == 0:
            factorial_valuation += 1
            remainder //= prime
        total_valuation += factorial_valuation
        index += 1
    return index - 1


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    for number in tokens[1:1 + case_count]:
        value = int(number)
        answer = 1
        for prime, exponent in prime_factors(value):
            candidate = increasing_index(prime, exponent)
            if candidate > answer:
                answer = candidate
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


def brute(number):
    running = 1
    factorial = 1
    for index in range(1, number + 1):
        factorial *= index
        running *= factorial
        if running % number == 0:
            return index
    return number


SAMPLE = """3
4
5
6
"""
SAMPLE_OUT = """3
5
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("4\n2\n4\n8\n9\n") == "2\n3\n4\n4\n"
assert increasing_index(2, 3) == 4
assert increasing_index(3, 2) == 4
for small in range(1, 201):
    assert brute(small) == int(oracle(str(1) + "\n" + str(small) + "\n").strip())


def write(name, numbers):
    text = str(len(numbers)) + "\n" + "".join(str(number) + "\n" for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 8, 9, 16, 27, 64, 100, 999999937])
    write("3_wide", [999999937, 999999929, 999999899, 999999893, 999999883,
                     999999869, 999999863, 999999853, 999999833, 999999829])
    rng = random.Random(20261126)
    numbers = []
    for _ in range(2000):
        candidate = 1
        for _ in range(rng.randint(1, 4)):
            candidate *= rng.choice([2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37])
        numbers.append(candidate if candidate < 10**9 else 999999937)
    write("4_random", numbers)
    io_numbers = [rng.randint(2, 10**9 - 1) for _ in range(10000)]
    io_numbers[0] = 999999937
    write("5_io", io_numbers)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
