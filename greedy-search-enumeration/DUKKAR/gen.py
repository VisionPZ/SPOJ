#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_one(row_number, prime):
    divisible = 0
    for index in range(row_number + 1):
        if math.comb(row_number, index) % prime == 0:
            divisible += 1
    return divisible


def count_not_divisible(row_number, prime):
    if row_number == 0:
        return 1
    return (row_number % prime + 1) * count_not_divisible(row_number // prime, prime)


def oracle_one(row_number, prime):
    return row_number + 1 - count_not_divisible(row_number, prime)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        answers.append(str(oracle_one(tokens[cursor], tokens[cursor + 1])))
        cursor += 2
    return "\n".join(answers) + "\n"


SAMPLE = """2
2 2
7 7
"""
SAMPLE_OUT = """1
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
for row in range(0, 60):
    for prime in (2, 3, 5, 7, 11):
        assert brute_one(row, prime) == oracle_one(row, prime)
assert oracle_one(0, 2) == 0
assert oracle_one(2, 2) == 1
assert oracle_one(7, 7) == 6
assert oracle_one(101, 101) == 100
assert oracle_one(2**60 - 1, 2) == 0


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{row_number} {prime}\n" for row_number, prime in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(0, 2), (1, 2), (2, 2), (101, 101),
                      (2**60 - 1, 2), (10**18, 99991)])
    rng = random.Random(20261126)
    wide_pairs = []
    for _ in range(200):
        exponent = rng.randint(1, 60)
        prime = rng.choice([2, 3, 5, 7, 11, 101, 65537, 99991])
        wide_pairs.append((rng.randint(0, 2**exponent), prime))
    write("3_wide", wide_pairs)
    write("4_random", [(rng.randint(0, 10**18), rng.choice(
        [2, 3, 5, 7, 11, 97, 1009, 99991])) for _ in range(1000)])
    write("5_io", [(rng.randint(0, 10**18), rng.choice(
        [2, 3, 5, 7, 11, 97, 1009, 99991])) for _ in range(99999)])
    prime_choices = [2, 3, 5, 7, 11, 97, 1009, 65537, 99991]
    big_pairs = [(rng.randint(0, 10**18), rng.choice(prime_choices))
                 for _ in range(99999)]
    Path("/tmp/DUKKAR_big.txt").write_text(
        str(len(big_pairs)) + "\n" + "".join(
            f"{row_number} {prime}\n" for row_number, prime in big_pairs))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 2), (7, 7)])
build()
