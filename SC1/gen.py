#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(case):
    initial, mineral_rate, gas_rate, cost, mineral_goal, gas_goal = case
    states = {(initial, 0, 0, 0)}
    for elapsed in range(60):
        following = set()
        for active, remaining, minerals, gas in states:
            for start in (False, True):
                if start and remaining == 0 and minerals >= cost:
                    next_active, next_remaining = active, 3
                    next_minerals = minerals - cost
                else:
                    next_active, next_remaining = active, remaining
                    next_minerals = minerals
                limit = mineral_goal + 3 * cost
                for miners in range(next_active + 1):
                    new_minerals = min(limit, next_minerals + miners * mineral_rate)
                    new_gas = min(gas_goal, gas + (next_active - miners) * gas_rate)
                    if next_remaining > 0:
                        leftover = next_remaining - 1
                        if leftover == 0:
                            following.add((next_active + 1, 0, new_minerals, new_gas))
                        else:
                            following.add((next_active, leftover, new_minerals, new_gas))
                    else:
                        following.add((next_active, 0, new_minerals, new_gas))
        if any(minerals >= mineral_goal and gas >= gas_goal
               for active, remaining, minerals, gas in following):
            return str(elapsed + 1) + "\n"
        states = following
    raise ValueError("no solution within horizon")


def oracle_text(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    cases = [tuple(tokens[1 + index * 6:7 + index * 6]) for index in range(count)]
    return "".join(oracle(case) for case in cases)


SAMPLE = """1
1 2 3 4 5 6
"""
SAMPLE_OUT = """5
"""
assert oracle_text(SAMPLE) == SAMPLE_OUT
assert oracle((1, 10, 2, 5, 2, 8)) == "5\n"
assert oracle((2, 8, 7, 4, 2, 8)) == "2\n"
assert oracle((3, 1, 1, 1, 20, 20)) == "11\n"
assert oracle((1, 1, 1, 20, 20, 20)) == "40\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    text += "".join(" ".join(str(value) for value in case) + "\n" for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(text))


def build():
    write("2_edges", [
        (1, 1, 1, 1, 1, 1), (1, 1, 1, 20, 20, 20),
        (20, 20, 20, 20, 1, 1), (1, 20, 20, 1, 1, 20)])
    write("3_wide", [
        (1, 20, 20, 20, 20, 20), (4, 1, 1, 8, 20, 20),
        (20, 1, 1, 20, 20, 20), (2, 3, 5, 4, 20, 20)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(200):
        random_cases.append((rng.randint(1, 8), rng.randint(1, 12),
                             rng.randint(1, 12), rng.randint(1, 12),
                             rng.randint(1, 20), rng.randint(1, 20)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(1000):
        io_cases.append((rng.randint(1, 4), rng.randint(1, 10),
                         rng.randint(1, 10), rng.randint(1, 10),
                         rng.randint(1, 20), rng.randint(1, 20)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 2, 3, 4, 5, 6)])
build()
