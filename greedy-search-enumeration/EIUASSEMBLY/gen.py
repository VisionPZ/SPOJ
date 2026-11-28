#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        robot_count = tokens[cursor]
        budget = tokens[cursor + 1]
        cursor += 2
        rates = []
        costs = []
        for _ in range(robot_count):
            rates.append(tokens[cursor])
            costs.append(tokens[cursor + 1])
            cursor += 2
        remaining = budget
        while remaining > 0:
            smallest = min(rates)
            bottleneck = [index for index in range(robot_count)
                          if rates[index] == smallest]
            unit_cost = sum(costs[index] for index in bottleneck)
            higher = [rates[index] for index in range(robot_count)
                      if rates[index] > smallest]
            if higher:
                next_rate = min(higher)
            else:
                next_rate = smallest + remaining // unit_cost + 1
            jump = min(next_rate - smallest, remaining // unit_cost)
            if jump <= 0:
                break
            for index in bottleneck:
                rates[index] += jump
            remaining -= jump * unit_cost
        answers.append(str(min(rates)))
    return "\n".join(answers) + "\n"


SAMPLE = """1
3 7
1 2
2 3
3 1
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 0\n1 2\n2 3\n3 1\n") == "1\n"
assert oracle("1\n1 1000000000000\n1 1\n") == "1000000000001\n"
assert oracle("2\n2 5\n4 1\n9 7\n2 12\n5 2\n8 3\n") == "9\n9\n"


def write(name, cases):
    lines = [str(len(cases))]
    for budget, robots in cases:
        lines.append(f"{len(robots)} {budget}")
        for base_rate, upgrade_cost in robots:
            lines.append(f"{base_rate} {upgrade_cost}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, [(1, 1), (5, 100)]),
                      (1, [(1, 1), (1, 1)]),
                      (1000000000000, [(1, 1)])])
    write("3_wide", [(10**12, [(1, 1), (10**9, 10**9), (999999999, 1)]),
                     (999999999999, [(10**9, 10**9)] * 10)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(8):
        count = rng.randint(1, 30)
        robots = [(rng.randint(1, 100), rng.randint(1, 100))
                  for _ in range(count)]
        random_cases.append((rng.randint(0, 100000), robots))
    write("4_random", random_cases)
    io_cases = []
    for case_index in range(10):
        robots = [(rng.randint(1, 10**9), rng.randint(1, 10**9))
                  for _ in range(100000)]
        io_cases.append((10**12, robots))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
