#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def matrix_power(matrix, exponent):
    size = len(matrix)
    result = [[1 if row == col else 0 for col in range(size)] for row in range(size)]
    while exponent:
        if exponent & 1:
            result = [[sum(result[row][mid] * matrix[mid][col] for mid in range(size)) % MOD
                       for col in range(size)] for row in range(size)]
        matrix = [[sum(matrix[row][mid] * matrix[mid][col] for mid in range(size)) % MOD
                   for col in range(size)] for row in range(size)]
        exponent >>= 1
    return result


@lru_cache(maxsize=None)
def oracle_value(target):
    if target == 0:
        return 1
    if target == 1:
        return 0
    transition = [[0, 1, 1], [1, 0, 0], [0, 1, 0]]
    powered = matrix_power(transition, target - 2)
    state = [1, 0, 1]
    return sum(powered[0][index] * state[index] for index in range(3)) % MOD


def brute_value(target):
    @lru_cache(maxsize=None)
    def recurse(remaining):
        if remaining == 0:
            return 1
        total = 0
        if remaining >= 2:
            total += recurse(remaining - 2)
        if remaining >= 3:
            total += recurse(remaining - 3)
        return total

    return recurse(target)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    return "\n".join(str(oracle_value(value)) for value in tokens[1:]) + "\n"


SAMPLE = """3
2
3
8
"""
SAMPLE_OUT = """1
1
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert all(brute_value(value) == oracle_value(value) for value in range(40))
assert oracle_value(1) == 0
assert oracle_value(4) == 1
assert oracle_value(10) == 7
assert oracle_value(1000000) == (oracle_value(999998) + oracle_value(999997)) % MOD


def write(name, targets):
    text = f"{len(targets)}\n" + "\n".join(str(value) for value in targets) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [1000000, 999999, 999998, 500000])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000) for _ in range(200)])
    pool = [1, 2, 3, 4, 5, 8, 10, 100, 1000, 1000000]
    write("5_io", [rng.choice(pool) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 3, 8])
build()
