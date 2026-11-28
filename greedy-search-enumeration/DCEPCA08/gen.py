#!/usr/bin/env python3
import random
from itertools import combinations
from math import isqrt
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SEQUENCE = [1]
for INDEX in range(1, 300):
    SEQUENCE.append((51 * SEQUENCE[-1] + 52) % 53 + 1)


def is_prime(value):
    return value >= 2 and all(value % divisor for divisor in range(2, isqrt(value) + 1))


def reachable_sums(length):
    reachable = {0}
    for value in SEQUENCE[1:length + 1]:
        reachable |= {total + value for total in reachable}
    return reachable


def oracle_case(length):
    reachable = reachable_sums(length)
    return str(sum(1 for total in reachable if is_prime(total)))


def oracle(text):
    tokens = [int(token) for token in text.split()]
    case_count = tokens[0]
    return "\n".join(oracle_case(tokens[index]) for index in range(1, case_count + 1)) + "\n"


SAMPLE = """2
4
5
"""
SAMPLE_OUT = """3
6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "0\n"
assert oracle("1\n4\n") == "3\n"
assert oracle("1\n5\n") == "6\n"
assert oracle("1\n6\n") == "13\n"
assert oracle("1\n52\n") == str(sum(1 for value in range(1379) if is_prime(value))) + "\n"
for length in range(1, 13):
    values = SEQUENCE[1:length + 1]
    brute = set()
    for taken in range(length + 1):
        for positions in combinations(range(length), taken):
            brute.add(sum(values[position] for position in positions))
    assert oracle_case(length) == str(sum(1 for value in brute if is_prime(value)))


def write(name, lengths):
    text = f"{len(lengths)}\n" + "\n".join(str(length) for length in lengths) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 51, 52, 53, 104])
    write("3_wide", [100, 101, 102, 103])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 200) for _ in range(12)])
    write("5_io", [rng.randint(50, 120) for _ in range(40)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [4, 5])
build()
