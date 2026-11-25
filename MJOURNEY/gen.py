#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pig_count = tokens[0]
    fuel_cost = tokens[1]
    weights = tokens[2:2 + pig_count]
    distances = tokens[2 + pig_count:2 + 2 * pig_count]
    prices = tokens[2 + 2 * pig_count:2 + 3 * pig_count]
    values = [price - fuel_cost * distance for price, distance in zip(prices, distances)]
    if pig_count <= 8:
        best_profit = None
        best_assignment = None
        for assignment in itertools.permutations(range(pig_count)):
            profit = sum(weights[pig] * values[village] for village, pig in enumerate(assignment))
            if best_profit is None or profit > best_profit:
                best_profit = profit
                best_assignment = assignment
    else:
        remaining_weights = set(range(pig_count))
        remaining_values = set(range(pig_count))
        best_assignment = [0] * pig_count
        for _ in range(pig_count):
            pig = min(remaining_weights, key=lambda index: (weights[index], index))
            village = min(remaining_values, key=lambda index: (values[index], index))
            best_assignment[village] = pig
            remaining_weights.remove(pig)
            remaining_values.remove(village)
    return " ".join(str(index + 1) for index in best_assignment) + "\n"


SAMPLE = """3 1
10 20 15
10 20 30
50 70 60
"""
SAMPLE_OUT = """3 2 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n5\n2\n10\n") == "1\n"
assert oracle("2 1\n10 20\n1 2\n100 50\n") == "2 1\n"
assert oracle("2 1\n20 10\n1 2\n50 100\n") == "2 1\n"
rng_check = random.Random(101)
check_weights = rng_check.sample(range(1, 100), 5)
check_values = rng_check.sample(range(1, 100), 5)
check_text = "5 1\n" + " ".join(map(str, check_weights)) + "\n" + "1 2 3 4 5\n" + " ".join(str(value + 1) for value in check_values) + "\n"
assert oracle(check_text).count(" ") == 4


def write(name, pig_count, fuel_cost, weights, distances, prices):
    text = f"{pig_count} {fuel_cost}\n" + " ".join(map(str, weights)) + "\n" + \
           " ".join(map(str, distances)) + "\n" + " ".join(map(str, prices)) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1000000000, [1000000000], [1], [1000000000])
    rng = random.Random(20261126)
    write("3_wide", 8, 1000000000,
          rng.sample(range(1, 1000000000), 8),
          rng.sample(range(1, 1000000), 8),
          rng.sample(range(1000000000 - 1000000, 1000000000), 8))
    write("4_random", 8, rng.randint(1, 1000),
          rng.sample(range(1, 1000000000), 8),
          rng.sample(range(1, 1000000), 8),
          rng.sample(range(1, 1000000000), 8))
    io_distances = rng.sample(range(1, 1000001), 1000)
    io_prices = [1000001 + 2 * distance for distance in io_distances]
    write("5_io", 1000, 1,
          rng.sample(range(1, 1000000000), 1000),
          io_distances,
          io_prices)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
