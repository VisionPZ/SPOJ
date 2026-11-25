#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def selection_cost(sizes, prices):
    remaining_sizes = list(sizes)
    remaining_prices = list(prices)
    total = 0
    while remaining_sizes:
        smallest_index = 0
        for index in range(1, len(remaining_sizes)):
            if remaining_sizes[index] < remaining_sizes[smallest_index]:
                smallest_index = index
        largest_index = 0
        for index in range(1, len(remaining_prices)):
            if remaining_prices[index] > remaining_prices[largest_index]:
                largest_index = index
        total += remaining_sizes.pop(smallest_index) * remaining_prices.pop(largest_index)
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = tokens[cursor]
        cursor += 1
        if count == 0:
            break
        sizes = tokens[cursor:cursor + count]
        cursor += count
        prices = tokens[cursor:cursor + count]
        cursor += count
        answers.append(str(selection_cost(sizes, prices)))
    return "\n".join(answers) + "\n"


SAMPLE = """4
1 1 1 1
2 2 2 2
5
10 80 37 22 109
6 8 8 20 15
0
"""
SAMPLE_OUT = """8
2120
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n100000\n100000\n0\n") == "10000000000\n"
assert oracle("2\n1 5\n2 9\n0\n") == "19\n"


def brute(sizes, prices):
    return min(sum(size * price for size, price in zip(sizes, assignment))
               for assignment in itertools.permutations(prices))


assert brute([1, 5], [2, 9]) == 19
assert brute([3, 1, 4], [7, 2, 5]) == 30
assert selection_cost([3, 1, 4], [7, 2, 5]) == 30


def write(name, cases):
    parts = []
    for sizes, prices in cases:
        parts.append(str(len(sizes)))
        parts.append(" ".join(str(value) for value in sizes))
        parts.append(" ".join(str(value) for value in prices))
    parts.append("0")
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1], [100000]), ([100000], [1]), ([1, 1], [99999, 100000])])
    rng = random.Random(20261126)
    write("3_wide", [([rng.randint(1, 100000) for _ in range(300)],
                      [rng.randint(1, 100000) for _ in range(300)])])
    random_cases = []
    for _ in range(20):
        count = rng.randint(2, 100)
        random_cases.append(([rng.randint(1, 100000) for _ in range(count)],
                             [rng.randint(1, 100000) for _ in range(count)]))
    write("4_random", random_cases)
    io_cases = [([rng.randint(1, 100000) for _ in range(50)],
                 [rng.randint(1, 100000) for _ in range(50)]) for _ in range(50)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
