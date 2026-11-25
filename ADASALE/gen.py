#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NEG = -10 ** 15


def prefix_costs(constant, city_number, modulus, bag_limit):
    totals = [0] * (bag_limit + 1)
    for item in range(1, bag_limit + 1):
        totals[item] = totals[item - 1] + (constant * item * city_number) % modulus
    return totals


def oracle(text):
    tokens = [int(value) for value in text.split()]
    city_count, bag_limit, modulus = tokens[0], tokens[1], tokens[2]
    licences = tokens[3:3 + city_count]
    constants = tokens[3 + city_count:3 + 2 * city_count]
    best_by_count = [NEG] * (bag_limit + 1)
    best_by_count[0] = 0
    for city_index in range(city_count):
        costs = prefix_costs(constants[city_index], city_index + 1, modulus, bag_limit)
        updated = best_by_count[:]
        fee = licences[city_index]
        for held in range(bag_limit + 1):
            if best_by_count[held] <= NEG // 2:
                continue
            for target in range(bag_limit + 1):
                candidate = best_by_count[held] + costs[held] - costs[target] - fee
                if candidate > updated[target]:
                    updated[target] = candidate
        best_by_count = updated
    return str(max(best_by_count)) + "\n"


def subset_brute(text):
    tokens = [int(value) for value in text.split()]
    city_count, bag_limit, modulus = tokens[0], tokens[1], tokens[2]
    licences = tokens[3:3 + city_count]
    constants = tokens[3 + city_count:3 + 2 * city_count]
    all_costs = [prefix_costs(constants[city], city + 1, modulus, bag_limit)
                 for city in range(city_count)]
    answer = NEG
    for mask in range(1 << city_count):
        best_by_count = [NEG] * (bag_limit + 1)
        best_by_count[0] = 0
        for city in range(city_count):
            if not (mask >> city) & 1:
                continue
            costs = all_costs[city]
            updated = best_by_count[:]
            for held in range(bag_limit + 1):
                if best_by_count[held] <= NEG // 2:
                    continue
                for target in range(bag_limit + 1):
                    candidate = best_by_count[held] + costs[held] - costs[target] - licences[city]
                    if candidate > updated[target]:
                        updated[target] = candidate
            best_by_count = updated
        answer = max(answer, max(best_by_count))
    return str(answer) + "\n"


SAMPLE = """5 1 3
1 1 1 1 1
1 1 1 1 1
"""
SAMPLE_OUT = """0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5 5 6\n1 1 1 1 1\n1 1 1 1 1\n") == "9\n"
assert oracle("6 10 11\n1 2 3 3 2 1\n1 3 2 5 1 7\n") == "19\n"
assert oracle("9 2 20\n6 6 6 6 6 6 6 6 6\n2 4 6 8 2 4 6 8 5\n") == "16\n"
assert oracle("10 2 20\n5 9 3 4 7 5 2 4 7 2\n2 1 4 5 4 5 6 3 2 5\n") == "25\n"

rng = random.Random(20261126)
for _ in range(30):
    city_count = rng.randint(1, 5)
    bag_limit = rng.randint(1, 4)
    modulus = rng.randint(1, 12)
    licences = [rng.randint(1, 8) for _ in range(city_count)]
    constants = [rng.randint(1, 8) for _ in range(city_count)]
    text = (f"{city_count} {bag_limit} {modulus}\n"
            + " ".join(map(str, licences)) + "\n"
            + " ".join(map(str, constants)) + "\n")
    assert oracle(text) == subset_brute(text)


def write(name, city_count, bag_limit, modulus, licences, constants):
    text = (f"{city_count} {bag_limit} {modulus}\n"
            + " ".join(map(str, licences)) + "\n"
            + " ".join(map(str, constants)) + "\n")
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    write("2_edges", 5, 1, 1, [1000] * 5, [1000] * 5)
    write("3_wide", 50, 60, 10000, [1000] * 50, [1000] * 50)
    write("4_random", 40, 25, 997,
          [rng.randint(1, 1000) for _ in range(40)],
          [rng.randint(1, 1000) for _ in range(40)])
    write("5_io", 300, 60, 10000,
          [rng.randint(1, 1000) for _ in range(300)],
          [rng.randint(1, 1000) for _ in range(300)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, 1, 3, [1] * 5, [1] * 5)
build()
