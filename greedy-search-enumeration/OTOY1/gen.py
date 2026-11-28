#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
MAX_K = 500
PRIME_COUNT = 500


def first_primes(count):
    limit = 5000
    composite = [False] * limit
    primes = []
    for candidate in range(2, limit):
        if not composite[candidate]:
            primes.append(candidate)
            if len(primes) == count:
                return primes
            for multiple in range(candidate * candidate, limit, candidate):
                composite[multiple] = True
    return primes


PRIMES = first_primes(PRIME_COUNT)


def series_for(prime_count):
    denominator = [1]
    for index in range(prime_count):
        prime = PRIMES[index]
        expanded = [0] * (len(denominator) + 1)
        for degree, value in enumerate(denominator):
            expanded[degree] = (expanded[degree] + value) % MOD
            expanded[degree + 1] = (expanded[degree + 1] - value * prime) % MOD
        denominator = expanded
    series = [0] * (MAX_K + 1)
    series[0] = 1
    for degree in range(1, MAX_K + 1):
        total = 0
        for offset in range(1, min(degree, prime_count) + 1):
            total = (total + denominator[offset] * series[degree - offset]) % MOD
        series[degree] = (-total) % MOD
    return series


SERIES = {prime_count: series_for(prime_count) for prime_count in range(1, PRIME_COUNT + 1)}
PREFACTOR = [1]
for prime in PRIMES:
    PREFACTOR.append(PREFACTOR[-1] * (prime - 1) % MOD)


def totient(number):
    result = number
    remaining = number
    divisor = 2
    while divisor * divisor <= remaining:
        if remaining % divisor == 0:
            while remaining % divisor == 0:
                remaining //= divisor
            result -= result // divisor
        divisor += 1
    if remaining > 1:
        result -= result // remaining
    return result


def brute_sum(prime_degree, prime_count):
    exponents = [0] * prime_count
    total = 0

    def walk(position, remaining):
        nonlocal total
        if position == prime_count:
            if remaining != 0:
                return
            value = 1
            for index, power in enumerate(exponents):
                value *= PRIMES[index] ** power
            total = (total + totient(value)) % MOD
            return
        for power in range(1, remaining - (prime_count - position - 1) + 1):
            exponents[position] = power
            walk(position + 1, remaining - power)

    walk(0, prime_degree)
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    lines = []
    for case_index in range(1, case_count + 1):
        prime_degree = tokens[cursor]
        prime_count = tokens[cursor + 1]
        cursor += 2
        answer = PREFACTOR[prime_count] * SERIES[prime_count][prime_degree - prime_count] % MOD
        lines.append(f"Case {case_index}: {answer}")
    return "\n".join(lines) + "\n"


SAMPLE = """3
3 2
5 4
99 45
"""
SAMPLE_OUT = """Case 1: 10
Case 2: 816
Case 3: 49939643
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert PRIMES[0] == 2 and PRIMES[1] == 3 and PRIMES[499] == 3571
assert totient(12) == 4
assert brute_sum(3, 2) == 10
assert brute_sum(5, 4) == 816
assert oracle("2\n1 1\n500 500\n") == "Case 1: 1\nCase 2: 447951633\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{prime_degree} {prime_count}\n" for prime_degree, prime_count in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (2, 1), (2, 2), (500, 1), (500, 250), (500, 500)])
    write("3_wide", [(500, prime_count) for prime_count in range(1, 501)])
    rng = random.Random(20261126)
    random_pairs = []
    for _ in range(2000):
        prime_count = rng.randint(1, MAX_K)
        random_pairs.append((rng.randint(prime_count, MAX_K), prime_count))
    write("4_random", random_pairs)
    pairs = []
    for _ in range(10000):
        prime_count = rng.randint(1, MAX_K)
        pairs.append((rng.randint(prime_count, MAX_K), prime_count))
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
