#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def best_interest(units, bonds):
    memo = {0: 0}
    stack = [units]
    while stack:
        remaining = stack[-1]
        if remaining in memo:
            stack.pop()
            continue
        missing = [remaining - value for value, _ in bonds
                   if value <= remaining and remaining - value not in memo]
        if missing:
            stack.extend(missing)
            continue
        answer = 0
        for value, interest in bonds:
            if value <= remaining:
                answer = max(answer, memo[remaining - value] + interest)
        memo[remaining] = answer
        stack.pop()
    return memo[units]


def brute_interest(units, bonds):
    best = 0

    def visit(bond_index, remaining, interest):
        nonlocal best
        if bond_index == len(bonds) or remaining == 0:
            best = max(best, interest)
            return
        value, earned = bonds[bond_index]
        for count in range(remaining // value + 1):
            visit(bond_index + 1, remaining - count * value, interest + count * earned)

    visit(0, units, 0)
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        capital = tokens[position]
        years = tokens[position + 1]
        position += 2
        bond_count = tokens[position]
        position += 1
        bonds = []
        for _ in range(bond_count):
            bonds.append((tokens[position] // 1000, tokens[position + 1]))
            position += 2
        for _ in range(years):
            capital += best_interest(capital // 1000, bonds)
        answers.append(str(capital))
    return "\n".join(answers) + "\n"


SAMPLE = """1
10000 4
2
4000 400
3000 250
"""
SAMPLE_OUT = """14050
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1000 1\n1\n1000 100\n") == "1100\n"
assert oracle("1\n500 2\n1\n1000 100\n") == "500\n"
assert oracle("1\n10000 1\n2\n4000 400\n3000 250\n") == "10900\n"
assert best_interest(12, [(4, 400), (3, 250)]) == brute_interest(12, [(4, 400), (3, 250)])


def build_case(start, years, bonds):
    lines = [f"{start} {years}", str(len(bonds))]
    for value, interest in bonds:
        lines.append(f"{value} {interest}")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(build_case(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(500, 2, [(1000, 100)]), (1000, 40, [(1000, 0)])])
    wide_bonds = [(1000 * size, 100 * size) for size in range(1, 11)]
    write("3_wide", [(1000000, 40, wide_bonds)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(4):
        start = rng.randint(1000, 50000)
        bonds = []
        for _ in range(rng.randint(1, 5)):
            value_units = rng.randint(1, 10)
            bonds.append((1000 * value_units, rng.randint(0, value_units * 100)))
        random_cases.append((start, rng.randint(1, 8), bonds))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(100):
        value_units = rng.randint(1, 8)
        io_cases.append((10000, 6, [(1000 * value_units, value_units * 100)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
