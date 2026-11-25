#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def matrix_ways(stones, skip):
    size = skip + 1

    def multiply(left, right):
        return [[sum(left[row][mid] * right[mid][col] for mid in range(size)) % MOD
                 for col in range(size)] for row in range(size)]

    base = [[0] * size for _ in range(size)]
    for col in range(size):
        base[0][col] = 1
    for row in range(1, size):
        base[row][row - 1] = 1
    vector = [1] + [0] * (size - 1)
    exponent = stones + 1
    while exponent:
        if exponent & 1:
            vector = [sum(base[row][col] * vector[col] for col in range(size)) % MOD
                      for row in range(size)]
        base = multiply(base, base)
        exponent >>= 1
    return vector[0]


def brute_ways(stones, skip):
    @lru_cache(maxsize=None)
    def recurse(remaining):
        if remaining == 0:
            return 1
        total = 0
        for step in range(1, min(skip + 1, remaining) + 1):
            total += recurse(remaining - step)
        return total

    return recurse(stones + 1)


@lru_cache(maxsize=None)
def cached_ways(stones, skip):
    return matrix_ways(stones, skip)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    test_count = tokens[cursor]
    cursor += 1
    lines = []
    for _ in range(test_count):
        river_count = tokens[cursor]
        skip = tokens[cursor + 1]
        cursor += 2
        for _ in range(river_count):
            stones = tokens[cursor]
            cursor += 1
            lines.append(str(cached_ways(stones, skip)))
    return "\n".join(lines) + "\n"


SAMPLE = """1
2 1
1 2
"""
SAMPLE_OUT = """2
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert all(brute_ways(stones, skip) == matrix_ways(stones, skip)
           for stones in range(12) for skip in range(5))
assert matrix_ways(0, 0) == 1
assert matrix_ways(100, 0) == 1
assert matrix_ways(2, 1) == 3
assert matrix_ways(8, 50) == 256


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1\n4 0\n0 1 2 100000\n")
    write("3_wide", "1\n3 50\n100000 99999 1\n")
    rng = random.Random(20261126)
    parts = []
    for _ in range(5):
        skip = rng.randint(0, 10)
        stones = [rng.randint(0, 200) for _ in range(20)]
        parts.append(f"20 {skip}\n" + " ".join(str(value) for value in stones))
    write("4_random", "5\n" + "\n".join(parts) + "\n")
    pool = [0, 1, 2, 3, 5, 8, 13, 21, 34, 55]
    parts = []
    for _ in range(10):
        skip = rng.choice([0, 1, 2, 3])
        stones = [rng.choice(pool) for _ in range(100)]
        parts.append(f"100 {skip}\n" + " ".join(str(value) for value in stones))
    write("5_io", "10\n" + "\n".join(parts) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
