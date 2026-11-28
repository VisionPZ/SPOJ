#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NEGATIVE = -10 ** 9


def format_case(case):
    batch_count, weapon_kinds, budget, opening, costs, ratings = case
    lines = [f"{batch_count} {weapon_kinds} {budget}"]
    lines.append(" ".join(str(value) for value in opening))
    lines.append(" ".join(str(value) for value in costs))
    lines.append(" ".join(str(value) for value in ratings))
    return "\n".join(lines)


def oracle_case(case):
    batch_count, weapon_kinds, budget, opening, costs, ratings = case
    batch_functions = []
    for batch in range(batch_count):
        weapon_values = [NEGATIVE] * (budget + 1)
        weapon_values[0] = 0
        for weapon in range(weapon_kinds):
            flat = batch * weapon_kinds + weapon
            price = costs[flat]
            power = ratings[flat]
            if price <= 0 or price > budget:
                continue
            for spent in range(price, budget + 1):
                if weapon_values[spent - price] >= 0:
                    weapon_values[spent] = max(weapon_values[spent], weapon_values[spent - price] + power)
        batch_values = [NEGATIVE] * (budget + 1)
        batch_values[0] = 0
        opening_price = opening[batch]
        if opening_price <= budget:
            for spent in range(opening_price, budget + 1):
                if weapon_values[spent - opening_price] >= 0:
                    batch_values[spent] = max(batch_values[spent], weapon_values[spent - opening_price])
        batch_functions.append(batch_values)
    combined = [NEGATIVE] * (budget + 1)
    combined[0] = 0
    for batch_values in batch_functions:
        updated = [NEGATIVE] * (budget + 1)
        for spent in range(budget + 1):
            if combined[spent] < 0:
                continue
            for extra in range(budget - spent + 1):
                if batch_values[extra] >= 0:
                    value = combined[spent] + batch_values[extra]
                    if value > updated[spent + extra]:
                        updated[spent + extra] = value
        combined = updated
    return max(combined)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        batch_count = tokens[cursor]
        weapon_kinds = tokens[cursor + 1]
        budget = tokens[cursor + 2]
        cursor += 3
        total = batch_count * weapon_kinds
        opening = tokens[cursor:cursor + batch_count]
        cursor += batch_count
        costs = tokens[cursor:cursor + total]
        cursor += total
        ratings = tokens[cursor:cursor + total]
        cursor += total
        answers.append(str(oracle_case((batch_count, weapon_kinds, budget, opening, costs, ratings))))
    return "\n".join(answers) + "\n"


def brute_case(case):
    batch_count, weapon_kinds, budget, opening, costs, ratings = case
    best = 0
    for mask in range(1 << batch_count):
        opening_spent = sum(opening[index] for index in range(batch_count) if mask >> index & 1)
        if opening_spent > budget:
            continue
        remaining = budget - opening_spent
        values = [0] * (remaining + 1)
        for batch in range(batch_count):
            if not (mask >> batch & 1):
                continue
            for weapon in range(weapon_kinds):
                flat = batch * weapon_kinds + weapon
                price = costs[flat]
                power = ratings[flat]
                if price <= 0 or price > remaining:
                    continue
                for spent in range(price, remaining + 1):
                    values[spent] = max(values[spent], values[spent - price] + power)
        best = max(best, max(values))
    return best


SAMPLE_INPUT = "1\n2 4 20\n3 4\n3 2 3 2\n3 2 3 5\n3 2 3 2\n4 5 6 5\n"
SAMPLE_OUTPUT = "40\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
COUNTEREXAMPLE = (3, 1, 14, [1, 1, 1], [5, 3, 7], [6, 3, 20])
assert oracle_case(COUNTEREXAMPLE) == 26
assert brute_case(COUNTEREXAMPLE) == 26
assert oracle_case((1, 1, 10, [3], [5], [6])) == 6
assert oracle_case((1, 1, 20, [3], [2], [5])) == 40
rng_check = random.Random(7)
for _ in range(40):
    batches = rng_check.randint(1, 4)
    kinds = rng_check.randint(1, 3)
    budget = rng_check.randint(1, 25)
    opening = [rng_check.randint(1, 6) for _ in range(batches)]
    costs = [rng_check.randint(1, 8) for _ in range(batches * kinds)]
    ratings = [rng_check.randint(1, 9) for _ in range(batches * kinds)]
    case = (batches, kinds, budget, opening, costs, ratings)
    assert oracle_case(case) == brute_case(case)


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(format_case(case) + "\n" for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, batches, kinds, budget):
    opening = [rng.randint(1, 20) for _ in range(batches)]
    costs = [rng.randint(1, 20) for _ in range(batches * kinds)]
    ratings = [rng.randint(1, 100) for _ in range(batches * kinds)]
    return (batches, kinds, budget, opening, costs, ratings)


def build():
    write("2_edges", [
        (1, 1, 1, [1], [1], [7]),
        (1, 1, 20, [3], [2], [5]),
        (2, 4, 20, [3, 4], [3, 2, 3, 2, 3, 2, 3, 5], [3, 2, 3, 2, 4, 5, 6, 5]),
        COUNTEREXAMPLE,
        (3, 2, 0, [1, 1, 1], [2, 2, 2, 2, 2, 2], [9, 9, 9, 9, 9, 9]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 20, 20, 1000)])
    random_cases = []
    for _ in range(12):
        batches = rng.randint(1, 5)
        kinds = rng.randint(1, 5)
        budget = rng.randint(1, 200)
        random_cases.append(random_case(rng, batches, kinds, budget))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(36000):
        opening = [rng.randint(1, 3)]
        costs = [rng.randint(1, 3)]
        ratings = [rng.randint(60, 100)]
        io_cases.append((1, 1, 10, opening, costs, ratings))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
