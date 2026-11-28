#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SIEVE_LIMIT = 15_000_000
IS_COMPOSITE = bytearray(SIEVE_LIMIT + 1)
PRIME_LIST = []
for candidate in range(2, SIEVE_LIMIT + 1):
    if not IS_COMPOSITE[candidate]:
        PRIME_LIST.append(candidate)
        if candidate * candidate <= SIEVE_LIMIT:
            for multiple in range(candidate * candidate, SIEVE_LIMIT + 1, candidate):
                IS_COMPOSITE[multiple] = 1


def vp_fact(value, prime):
    total = 0
    power = prime
    while power <= value:
        total += value // power
        if power > value // prime:
            break
        power *= prime
    return total


def binomial_exponent(first, second, prime):
    return vp_fact(first, prime) - vp_fact(second, prime) - vp_fact(first - second, prime)


def oracle(text):
    lines = [line for line in text.strip().split("\n") if line.strip()]
    answers = []
    for line in lines:
        polygon_size, piece_count, modulus = (int(value) for value in line.split())
        scaled_modulus = modulus * piece_count
        numerator = 1
        upper = polygon_size + piece_count - 2
        for prime in PRIME_LIST:
            if prime > upper:
                break
            exponent = (binomial_exponent(upper, piece_count - 1, prime) +
                        binomial_exponent(polygon_size - 3, piece_count - 1, prime))
            if exponent:
                numerator = numerator * pow(prime, exponent, scaled_modulus) % scaled_modulus
        answers.append(str((numerator // piece_count) % modulus))
    return "\n".join(answers) + "\n"


def exact_value(polygon_size, piece_count):
    return math.comb(polygon_size + piece_count - 2, piece_count - 1) * math.comb(polygon_size - 3, piece_count - 1) // piece_count


SAMPLE = "4 2 100\n6 3 100\n10000000 2 1000000007\n10000000 5000000 1000000014000000049\n"
SAMPLE_OUT = "2\n21\n984650007\n780127215155143528\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 1 7\n") == "1\n"
assert oracle("5 2 1000\n") == "5\n"
assert oracle("7 3 1000000007\n") == "56\n"
assert exact_value(4, 2) == 2
assert exact_value(6, 3) == 21
assert exact_value(7, 3) == 56


def write(name, cases):
    text = "".join(f"{polygon} {pieces} {modulus}\n" for polygon, pieces, modulus in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(3, 1, 1000000007), (3, 1, 97), (4, 1, 100), (4, 2, 100), (5, 3, 7), (6, 4, 1000)])
    write("3_wide", [(100, 1, 1000000007), (100, 50, 1000000007), (200, 3, 1000000014000000049),
                     (300, 150, 999999999999989), (500, 2, 97)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(12):
        polygon = rng.randint(3, 400)
        pieces = rng.randint(1, polygon - 2)
        modulus = rng.choice([100, 1000000007, 1000000014000000049, 999999999999989, 97])
        random_cases.append((polygon, pieces, modulus))
    write("4_random", random_cases)
    write("5_io", [(500 + index * 10, (500 + index * 10) // 2, 1000000014000000049)
                   for index in range(16)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, 2, 100), (6, 3, 100), (10000000, 2, 1000000007),
                   (10000000, 5000000, 1000000014000000049)])
build()
