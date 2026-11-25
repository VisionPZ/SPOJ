#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MEMO = {0: 0, 1: 0}


def smallest_prime_factor(value):
    if value % 2 == 0:
        return 2
    divisor = 3
    while divisor * divisor <= value:
        if value % divisor == 0:
            return divisor
        divisor += 2
    return value


def oracle_case(limit):
    if limit in MEMO:
        return MEMO[limit]
    total = 0
    for value in range(2, limit + 1):
        total += smallest_prime_factor(value)
    MEMO[limit] = total
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    test_count = tokens[0]
    limits = tokens[1:1 + test_count]
    return "\n".join(str(oracle_case(limit)) for limit in limits) + "\n"


SAMPLE = "3\n2\n3\n4\n"
SAMPLE_OUT = "2\n5\n7\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "0\n"
assert oracle("1\n5\n") == "12\n"
assert oracle("1\n10\n") == "28\n"
assert smallest_prime_factor(97) == 97
assert oracle("4\n2 3 4 5\n") == "2\n5\n7\n12\n"


def write(name, limits):
    input_text = str(len(limits)) + "\n" + "\n".join(str(limit) for limit in limits) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 10])
    write("3_wide", [4999, 5000, 4999, 5000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 5000) for _ in range(200)])
    write("5_io", [rng.randint(4900, 5000) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 3, 4])
build()
