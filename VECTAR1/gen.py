#!/usr/bin/env python3
import math
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


@lru_cache(maxsize=None)
def oracle_value(rows, columns):
    frequencies = [0] * 1024
    for row in range(1, rows + 1):
        for column in range(1, columns + 1):
            frequencies[row ^ column] += 1
    result = 1
    for frequency in frequencies:
        if frequency:
            result = result * math.factorial(frequency) % MOD
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    lines = []
    for index in range(count):
        rows = tokens[1 + 2 * index]
        columns = tokens[2 + 2 * index]
        lines.append(str(oracle_value(rows, columns)))
    return "\n".join(lines) + "\n"


SAMPLE = """1
2
2
"""
SAMPLE_OUT = """4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_value(1, 1) == 1
assert oracle_value(1, 2) == 1
assert oracle_value(2, 3) == 4
assert oracle_value(3, 3) == 48
assert oracle_value(4, 4) == 1536


def write(name, pairs):
    text = f"{len(pairs)}\n" + "\n".join(f"{rows}\n{columns}" for rows, columns in pairs) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 2), (2, 1), (2, 2), (3, 1), (1, 3)])
    write("3_wide", [(1000, 1000), (1000, 1), (1, 1000), (999, 1000)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 200), rng.randint(1, 200)) for _ in range(30)])
    pool = [(2, 2), (3, 3), (10, 10), (100, 100), (1000, 1000)]
    write("5_io", [rng.choice(pool) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 2)])
build()
