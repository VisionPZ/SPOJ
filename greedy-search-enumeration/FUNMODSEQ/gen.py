#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def inverse_or_none(value, modulus):
    try:
        return pow(value, -1, modulus)
    except ValueError:
        return None


@lru_cache(maxsize=None)
def oracle_value(first, modulus, terms):
    first_inverse = inverse_or_none(first, modulus)
    if first_inverse is None:
        return -1
    if terms <= 4:
        current = first
        total = 0
        for _ in range(terms):
            total += current
            current = inverse_or_none(current, modulus)
        return total
    assert inverse_or_none(first_inverse, modulus) == first
    pair_sum = first + first_inverse
    total = (terms // 2) * pair_sum
    if terms % 2:
        total += first
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    lines = []
    for index in range(count):
        first = tokens[1 + 3 * index]
        modulus = tokens[2 + 3 * index]
        terms = tokens[3 + 3 * index]
        lines.append(str(oracle_value(first, modulus, terms)))
    return "\n".join(lines) + "\n"


def exhaustive_inverse(value, modulus):
    for candidate in range(modulus):
        if value * candidate % modulus == 1:
            return candidate
    return None


SAMPLE = """2
2 3 2
3 7 2
"""
SAMPLE_OUT = """4
8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_value(2, 3, 2) == 4
assert oracle_value(3, 7, 3) == 11
assert oracle_value(2, 4, 5) == -1
assert oracle_value(1, 9, 1000000000) == 1000000000
for modulus in range(2, 30):
    for value in range(1, modulus):
        assert inverse_or_none(value, modulus) == exhaustive_inverse(value, modulus)


def write(name, triples):
    text = f"{len(triples)}\n" + "\n".join(f"{first} {modulus} {terms}"
                                           for first, modulus, terms in triples) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 4, 5), (4, 6, 3), (6, 9, 2), (1, 7, 1), (1, 7, 1000000000)])
    write("3_wide", [(2, 3, 1000000000), (3, 7, 999999999), (100000, 1000000000, 1000000000)])
    rng = random.Random(20261126)
    triples = []
    for _ in range(100):
        modulus = rng.randint(2, 1000000000)
        first = rng.randint(1, min(100000, modulus - 1))
        terms = rng.randint(1, 1000000000)
        triples.append((first, modulus, terms))
    write("4_random", triples)
    pool = [(2, 3, 1000000000), (3, 7, 999999999), (2, 4, 7), (1, 9, 1000000000),
            (7, 11, 123456789), (6, 35, 987654321)]
    write("5_io", [rng.choice(pool) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 3, 2), (3, 7, 2)])
build()
