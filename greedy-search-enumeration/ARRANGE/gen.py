#!/usr/bin/env python3
import math
import random
from itertools import permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = float("inf")


def log_tower(stack):
    if len(stack) == 1:
        return 0.0 if stack[0] == 1 else math.log(stack[0])
    if stack[-1] == 1:
        return 0.0
    lower = log_tower(stack[:-1])
    if lower > 700:
        return INF
    return math.exp(lower) * math.log(stack[-1])


def tower_key(order):
    stack = list(order)
    depth = 0
    while True:
        value = log_tower(stack)
        if value != INF:
            return (depth, value)
        if len(stack) == 1:
            return (depth, 0.0)
        stack = stack[:-1]
        depth += 1


def brute_order(values):
    best = None
    best_key = None
    for order in set(permutations(values)):
        key = tower_key(order)
        if best_key is None or key > best_key or (key == best_key and list(order) > list(best)):
            best_key = key
            best = list(order)
    return best


def fast_order(values):
    ones = [value for value in values if value == 1]
    large = sorted((value for value in values if value != 1), reverse=True)
    if len(large) >= 2 and large[0] == 3 and large[1] == 2:
        large[0], large[1] = 2, 3
    return ones + large


def oracle(text):
    tokens = [int(token) for token in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    lines = []
    for _ in range(case_count):
        size = tokens[cursor]
        cursor += 1
        values = tokens[cursor:cursor + size]
        cursor += size
        order = brute_order(values) if size <= 7 else fast_order(values)
        lines.append(" ".join(str(value) for value in order))
    return "\n".join(lines) + "\n"


SAMPLE = """2
3
5 6 4
2
2 3
"""
SAMPLE_OUT = """6 5 4
2 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n2 3\n") == "2 3\n"
assert oracle("1\n3\n3 2 4\n") == "4 3 2\n"
assert oracle("1\n4\n1 1 4 2\n") == "1 1 4 2\n"
assert brute_order([2, 3]) == [2, 3]
assert brute_order([5, 6, 4]) == [6, 5, 4]
rng_check = random.Random(77)
for _ in range(120):
    sample_values = [rng_check.randint(1, 6) for _ in range(rng_check.randint(1, 6))]
    assert brute_order(sample_values) == fast_order(sample_values)


def write_case(name, cases):
    chunks = [str(len(cases))]
    for values in cases:
        chunks.append(str(len(values)))
        chunks.append(" ".join(str(value) for value in values))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [[1], [1, 1], [3, 2], [1, 2, 3, 4], [10**9]])
    rng = random.Random(20261126)
    wide = []
    for _ in range(12):
        values = rng.sample(range(2, 10**9), 40)
        if rng.random() < 0.5:
            values = [1] * rng.randint(1, 3) + values
        wide.append(values)
    write_case("3_wide", wide)
    random_cases = []
    for _ in range(15):
        size = rng.randint(1, 12)
        random_cases.append(rng.sample(range(2, 10**9), size))
    write_case("4_random", random_cases)
    io_values = rng.sample(range(2, 10**9), 100000)
    write_case("5_io", [io_values])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
