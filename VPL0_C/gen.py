#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def divisor_count(value):
    total = 0
    candidate = 1
    while candidate * candidate <= value:
        if value % candidate == 0:
            total += 1
            if candidate * candidate != value:
                total += 1
        candidate += 1
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_total = tokens[0]
    lines = []
    cursor = 1
    for case_number in range(1, case_total + 1):
        number_limit = tokens[cursor]
        progression_step = tokens[cursor + 1]
        cursor += 2
        best_number = 0
        best_divisors = 0
        term_index = 0
        while True:
            term_value = 1 + term_index * progression_step + term_index * (term_index + 1) // 2
            if term_value > number_limit:
                break
            divisor_total = divisor_count(term_value)
            if divisor_total > best_divisors:
                best_divisors = divisor_total
                best_number = term_value
            term_index += 1
        lines.append(f"Scenario #{case_number}: {best_number} {best_divisors}")
    return "\n".join(lines) + "\n"


SAMPLE = """4
4 0
28 1
2 2
78 3
"""
SAMPLE_OUT = """Scenario #1: 4 3
Scenario #2: 28 6
Scenario #3: 1 1
Scenario #4: 40 8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4 0\n") == "Scenario #1: 4 3\n"
assert oracle("1\n2 2\n") == "Scenario #1: 1 1\n"
assert oracle("1\n78 3\n") == "Scenario #1: 40 8\n"
assert divisor_count(1) == 1
assert divisor_count(28) == 6


def write(name, cases):
    text = str(len(cases)) + "\n"
    text += "".join(f"{limit} {step}\n" for limit, step in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 0), (2, 100), (3, 0), (7, 100), (10, 5)])
    write("3_wide", [(1000000, 0), (1000000, 100), (999983, 37)])
    rng = random.Random(20261126)
    cases = [(rng.randint(1, 100000), rng.randint(0, 100)) for _ in range(25)]
    write("4_random", cases)
    cases = [(rng.randint(1, 3000), rng.randint(0, 100)) for _ in range(250)]
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, 0), (28, 1), (2, 2), (78, 3)])
build()

rng = random.Random(19471208)
big_cases = [(rng.randint(1, 10000000), rng.randint(0, 100)) for _ in range(100)]
big_text = str(len(big_cases)) + "\n"
big_text += "".join(f"{limit} {step}\n" for limit, step in big_cases)
Path("/tmp/VPL0_C_big.txt").write_text(big_text)
