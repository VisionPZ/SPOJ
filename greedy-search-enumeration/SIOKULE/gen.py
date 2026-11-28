#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def partitions(total, largest=None):
    if largest is None or largest > total:
        largest = total
    if total == 0:
        yield ()
        return
    for first in range(largest, 0, -1):
        for rest in partitions(total - first, first):
            yield (first,) + rest


@lru_cache(None)
def brute_value(cubes):
    if cubes == 1:
        return 0
    best = None
    for parts in partitions(cubes):
        if len(parts) < 2:
            continue
        paid = max((position + 1) ** 2 + brute_value(part)
                   for position, part in enumerate(parts))
        if best is None or paid < best:
            best = paid
    return best


@lru_cache(None)
def capacity(cost):
    if cost <= 3:
        return 1
    root = int(cost ** 0.5)
    while (root + 1) ** 2 <= cost:
        root += 1
    return sum(capacity(cost - step * step) for step in range(1, root + 1))


def formula_value(cubes):
    cost = 0
    while capacity(cost) < cubes:
        cost += 1
    return cost


def oracle(text):
    cubes = int(text.split()[0])
    if cubes <= 40:
        return str(brute_value(cubes)) + "\n"
    return str(formula_value(cubes)) + "\n"


SAMPLE = """7
"""
SAMPLE_OUT = """8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_value(2) == 4
assert brute_value(5) == 7
assert brute_value(12) == 10
assert all(brute_value(value) == formula_value(value) for value in range(1, 31))


def write(name, value):
    text = str(value) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2)
    rng = random.Random(20261126)
    write("3_wide", 10 ** 100)
    write("4_random", rng.randint(2, 10 ** 40))
    write("5_io", 10 ** 100)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
