#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
SMALL_POOL = [2, 3, 5, 7, 11, 13, 43, 101, 1009, 10007, 100003, 999983,
              1000000007, 1000000009, 2202335167, 999999999989, 1000000000039]


def is_prime(number):
    if number < 2:
        return False
    for small in (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37):
        if number == small:
            return True
        if number % small == 0:
            return False
    odd_part = number - 1
    shift = 0
    while odd_part % 2 == 0:
        odd_part //= 2
        shift += 1
    for base in BASES:
        value = pow(base, odd_part, number)
        if value == 1 or value == number - 1:
            continue
        for _ in range(shift - 1):
            value = value * value % number
            if value == number - 1:
                break
        else:
            return False
    return True


def find_prime(start):
    candidate = start if start % 2 else start + 1
    while not is_prime(candidate):
        candidate += 2
    return candidate


def brute(limit, prime):
    result = 1
    for number in range(1, limit + 1):
        result = result * number % prime
    return result


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    results = []
    position = 1
    for _ in range(count):
        limit = int(tokens[position])
        prime = int(tokens[position + 1])
        position += 2
        if limit >= prime:
            results.append("0")
            continue
        distance = prime - 1 - limit
        factorial = 1
        for factor in range(1, distance + 1):
            factorial = factorial * factor % prime
        inverse = pow(factorial, -1, prime)
        results.append(str((-inverse if distance % 2 == 0 else inverse) % prime))
    return "\n".join(results) + "\n"


SAMPLE = """3
2 5
5 11
21 71
"""
SAMPLE_OUT = """2
10
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(5, 11) == 10
assert oracle("1\n4 5\n") == "4\n"
assert oracle("1\n5 5\n") == "0\n"
for prime in (5, 7, 11, 43, 101):
    for limit in range(1, prime):
        assert oracle(f"1\n{limit} {prime}\n") == str(brute(limit, prime)) + "\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for limit, prime in cases:
        text += f"{limit} {prime}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    big_prime = find_prime(10**99 + 987654321)
    medium_prime = find_prime(10**49 + 123456789)
    write("2_edges", [(1, 2), (2, 3), (4, 5), (5, 5), (6, 5),
                      (big_prime - 1, big_prime), (medium_prime - 2, medium_prime)])
    write("3_wide", [(prime - 1 - distance, prime)
                     for prime in (big_prime, medium_prime, 9999999999995023)
                     for distance in (0, 1, 17, 255, 1000)])
    rng = random.Random(20261126)
    cases = []
    for _ in range(99):
        prime = rng.choice(SMALL_POOL + [big_prime, medium_prime])
        distance = rng.randint(0, min(2000, prime - 2))
        cases.append((prime - 1 - distance, prime))
    write("4_random", cases)
    write("5_io", [(medium_prime - 1 - rng.randint(0, 5000), medium_prime) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
