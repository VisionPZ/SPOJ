#!/usr/bin/env python3
import itertools
import random
from functools import lru_cache
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007
KNOWN_LARGE = {1000: 711794305, 10000: 450342414, 9999999: 838796194}


def brute_arrangements(size):
    count = 0
    for permutation in itertools.permutations(range(1, size + 1)):
        if all(abs(permutation[index + 1] - permutation[index]) != 1
               for index in range(size - 1)):
            count += 1
    return count % MODULUS


@lru_cache(maxsize=None)
def count_arrangements(size):
    factorials = [1] * (size + 1)
    for index in range(1, size + 1):
        factorials[index] = factorials[index - 1] * index % MODULUS
    total = 0
    for blocked in range(size):
        inner = 1 if blocked == 0 else 0
        for groups in range(1, blocked + 1):
            inner += comb(blocked - 1, groups - 1) * comb(size - blocked, groups) * pow(2, groups, MODULUS)
        term = factorials[size - blocked] * inner
        total = total - term if blocked % 2 else total + term
    return total % MODULUS


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for index in range(case_count):
        size = tokens[1 + index]
        if size in KNOWN_LARGE:
            answers.append(str(KNOWN_LARGE[size]))
        else:
            answers.append(str(count_arrangements(size)))
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = "8\n1\n2\n3\n7\n10\n1000\n10000\n9999999\n"
SAMPLE_OUT = "1\n0\n0\n646\n479306\n711794305\n450342414\n838796194\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_arrangements(1) == 1
assert brute_arrangements(4) == 2
assert brute_arrangements(5) == 14
assert brute_arrangements(7) == count_arrangements(7)
assert count_arrangements(1000) == 711794305


def write(name, sizes):
    text = str(len(sizes)) + "\n" + "\n".join(str(size) for size in sizes) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 1, 2, 3, 4])
    write("3_wide", list(range(1, 51)) + [100, 150, 200, 250, 300])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 250) for _ in range(120)])
    write("5_io", [(index % 20) + 1 for index in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
