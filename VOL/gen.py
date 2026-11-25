#!/usr/bin/env python3
import random
from pathlib import Path

import numpy as np
from scipy.optimize import linprog
from scipy.sparse import csr_matrix

ROOT = Path(__file__).resolve().parent


def oracle_case(day_count, needs, volunteers):
    row_indexes = []
    column_indexes = []
    for volunteer_index, (start_day, end_day, cost) in enumerate(volunteers):
        for day_index in range(start_day - 1, end_day):
            row_indexes.append(day_index)
            column_indexes.append(volunteer_index)
    values = -np.ones(len(row_indexes), dtype=float)
    constraint = csr_matrix((values, (row_indexes, column_indexes)),
                            shape=(day_count, len(volunteers)))
    costs = [volunteer[2] for volunteer in volunteers]
    result = linprog(costs, A_ub=constraint, b_ub=[-need for need in needs],
                     bounds=(0, None), method="highs")
    return int(round(result.fun))


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        day_count = tokens[cursor]
        volunteer_count = tokens[cursor + 1]
        cursor += 2
        needs = tokens[cursor:cursor + day_count]
        cursor += day_count
        volunteers = []
        for _ in range(volunteer_count):
            volunteers.append((tokens[cursor], tokens[cursor + 1], tokens[cursor + 2]))
            cursor += 3
        answers.append(str(oracle_case(day_count, needs, volunteers)))
    return "\n".join(answers) + "\n"


def brute_case(day_count, needs, volunteers):
    maximum = max(needs) + 1
    best = 10 ** 18
    counter = [0] * len(volunteers)

    def search(volunteer_index):
        nonlocal best
        if volunteer_index == len(volunteers):
            coverage = [0] * day_count
            cost = 0
            for count, (start, end, price) in zip(counter, volunteers):
                cost += count * price
                for day_index in range(start - 1, end):
                    coverage[day_index] += count
            if all(coverage[index] >= needs[index] for index in range(day_count)):
                best = min(best, cost)
            return
        for count in range(maximum):
            counter[volunteer_index] = count
            search(volunteer_index + 1)
        counter[volunteer_index] = 0

    search(0)
    return best


SAMPLE = """3 3
2 3 4
1 2 2
2 3 5
3 3 2
"""
SAMPLE_OUT = """14
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(2, [1, 1], [(1, 2, 7)]) == 7
assert oracle_case(1, [0], [(1, 1, 5)]) == 0
assert oracle_case(2, [2, 2], [(1, 1, 3), (2, 2, 4)]) == 14
small = (3, [2, 3, 4], [(1, 2, 2), (2, 3, 5), (3, 3, 2)])
assert oracle_case(*small) == brute_case(*small)


def render_case(day_count, needs, volunteers):
    lines = [f"{day_count} {len(volunteers)}", " ".join(str(value) for value in needs)]
    lines += [f"{start} {end} {cost}" for start, end, cost in volunteers]
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = "".join(render_case(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_case(rng, day_count, volunteer_count, price_limit):
    needs = [rng.randint(0, 20) for _ in range(day_count)]
    volunteers = []
    for _ in range(volunteer_count):
        start = rng.randint(1, day_count)
        end = rng.randint(start, day_count)
        volunteers.append((start, end, rng.randint(1, price_limit)))
    for day_index in range(day_count):
        if not any(start <= day_index + 1 <= end for start, end, _ in volunteers):
            volunteers.append((day_index + 1, day_index + 1, price_limit))
    return day_count, needs, volunteers


def build():
    edges = [(1, [0], [(1, 1, 5)]), (1, [3], [(1, 1, 5)]),
             (2, [0, 0], [(1, 2, 7)]), (2, [4, 4], [(1, 2, 3)])]
    write("2_edges", edges * 3)
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 120, 300, 1000) for _ in range(10)])
    write("4_random", [random_case(rng, 30, 60, 100) for _ in range(10)])
    write("5_io", [random_case(rng, 60, 100, 1000000000) for _ in range(10)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
