#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SIEVE_LIMIT = 300000
BIG_SUM = 24739512092254535
BIG_ANSWER = 999999937


def prime_sum_table(limit):
    composite = bytearray(limit + 1)
    table = {}
    total = 0
    for value in range(2, limit + 1):
        if not composite[value]:
            total += value
            table[total] = value
            if value * value <= limit:
                for multiple in range(value * value, limit + 1, value):
                    composite[multiple] = 1
    return table


TABLE = prime_sum_table(SIEVE_LIMIT)


def oracle(text):
    target = int(text.strip())
    if target == BIG_SUM:
        return str(BIG_ANSWER) + "\n"
    return str(TABLE[target]) + "\n"


SAMPLE = """77
"""
SAMPLE_OUT = """19
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(str(BIG_SUM) + "\n") == "999999937\n"
assert oracle("2\n") == "2\n"
assert oracle("5\n") == "3\n"
assert oracle("10\n") == "5\n"
assert TABLE[28] == 11


def write(name, target):
    text = str(target) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2)
    write("3_wide", BIG_SUM)
    rng = random.Random(20261126)
    write("4_random", rng.choice(sorted(TABLE)))
    write("5_io", BIG_SUM)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
