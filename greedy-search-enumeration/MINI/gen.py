#!/usr/bin/env python3
from itertools import product
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000009


def count_winning_boards(order):
    size = order ** order
    valid_vectors = []
    power_values = [order ** position for position in range(order)]
    for coordinates in product(range(order), repeat=order):
        if sum(coordinates) % order == 0:
            index = sum(value * power for value, power in zip(coordinates, power_values))
            valid_vectors.append(index)
    digits = [[(index // power) % order for power in power_values]
              for index in range(size)]
    addition_table = []
    for first in range(size):
        row = []
        for second in valid_vectors:
            combined = sum(((digits[first][position] + digits[second][position]) % order)
                           * power_values[position] for position in range(order))
            row.append(combined)
        addition_table.append(row)
    dp = [0] * size
    dp[0] = 1
    for _ in range(order):
        updated = [0] * size
        for first in range(size):
            ways = dp[first]
            if ways:
                for second in addition_table[first]:
                    updated[second] += ways
        dp = updated
    return dp[0] % MODULUS


KNOWN = {order: count_winning_boards(order) for order in range(1, 5)}


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    return "".join(str(KNOWN[tokens[index + 1]]) + "\n" for index in range(count))


SAMPLE = """1
1
"""
SAMPLE_OUT = """1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert KNOWN == {1: 1, 2: 2, 3: 81, 4: 262144}
assert pow(2, 1, MODULUS) == KNOWN[2]
assert pow(4, 9, MODULUS) == KNOWN[4]


def write(name, orders):
    text = str(len(orders)) + "\n" + "".join(str(order) + "\n" for order in orders)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4])
    write("3_wide", [4] * 100)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 4) for _ in range(200)])
    write("5_io", [rng.randint(1, 4) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1])
build()
