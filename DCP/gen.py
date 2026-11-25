#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parity_pattern(length):
    pattern = []
    previous_value, current_value = 0, 1
    pattern.append(previous_value % 2)
    while len(pattern) < length:
        pattern.append(current_value % 2)
        previous_value, current_value = current_value, previous_value + current_value
    return pattern


PATTERN = parity_pattern(12)


def count_even(lower, upper):
    length = upper - lower + 1
    full_triples, rest = divmod(length, 3)
    total = full_triples
    start = (lower - 1) % 3
    for offset in range(rest):
        if PATTERN[(start + offset) % 3] == 0:
            total += 1
    return total


def brute_even(lower, upper):
    values = [0, 1]
    while len(values) < upper:
        values.append(values[-1] + values[-2])
    return sum(1 for index in range(lower, upper + 1) if values[index - 1] % 2 == 0)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    lines = []
    offset = 1
    for case_index in range(1, case_count + 1):
        lower, upper = tokens[offset], tokens[offset + 1]
        offset += 2
        if lower > upper:
            lower, upper = upper, lower
        even = count_even(lower, upper)
        odd = upper - lower + 1 - even
        lines.append(f"Case {case_index}:\nOdd = {odd}\nEven = {even}\n")
    return "".join(lines)


SAMPLE = """2
2 6
1 5
"""
SAMPLE_OUT = """Case 1:
Odd = 4
Even = 1
Case 2:
Odd = 3
Even = 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n") == "Case 1:\nOdd = 0\nEven = 1\n"
assert oracle("2\n3 3\n6 6\n") == "Case 1:\nOdd = 1\nEven = 0\nCase 2:\nOdd = 1\nEven = 0\n"
assert oracle("1\n1000000000000000000 1000000000000000000\n").endswith("Odd = 0\nEven = 1\n")
assert all(count_even(low, high) == brute_even(low, high)
           for low in range(1, 8) for high in range(low, 20))
assert PATTERN == [0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1]


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{low} {high}\n" for low, high in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 2), (3, 3), (6, 6), (9, 9), (10, 12)])
    write("3_wide", [(10**18 - 5, 10**18), (1, 10**18), (10**18, 1),
                     (999999999999999999, 10**18)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(50):
        low = rng.randint(1, 10**18)
        high = rng.randint(1, 10**18)
        pairs.append((low, high))
    write("4_random", pairs)
    pairs = [(index * 37 + 1, index * 37 + 90) for index in range(1, 201)]
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 6), (1, 5)])
build()
