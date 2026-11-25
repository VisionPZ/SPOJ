#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        principal = int(tokens[cursor]); cursor += 1
        years = int(tokens[cursor]); cursor += 1
        simple_rate = int(tokens[cursor]); cursor += 1
        compound_rate = int(tokens[cursor]); cursor += 1
        simple_interest = Fraction(principal * simple_rate * years, 100)
        compound_interest = Fraction(principal) * (Fraction(100 + compound_rate, 100) ** years - 1)
        if simple_interest < compound_interest:
            answers.append("Bank 1")
        elif simple_interest > compound_interest:
            answers.append("Bank 2")
        else:
            answers.append("Confused huh!")
    return "\n".join(answers) + "\n"


SAMPLE = """4
10000 5 10 15
2000 4 3 5
100 3 5 4
12345 3 9 7
"""
SAMPLE_OUT = """Bank 1
Bank 1
Bank 2
Bank 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n100 1 5 5\n") == "Confused huh!\n"
assert oracle("1\n100 2 22 20\n") == "Confused huh!\n"
assert oracle("1\n100 2 21 20\n") == "Bank 1\n"
assert Fraction(22 * 2, 100) == Fraction(120, 100) ** 2 - 1


def write(name, cases):
    rows = [str(len(cases))]
    for principal, years, simple_rate, compound_rate in cases:
        rows.append(f"{principal} {years} {simple_rate} {compound_rate}")
    text = "\n".join(rows) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 1, 3, 3), (1000000000, 1, 50, 50), (100, 1, 50, 3),
        (1, 2, 22, 20), (1, 2, 21, 20), (1, 2, 23, 20),
        (1000000000, 50, 3, 3), (1000000000, 50, 50, 50),
    ])
    write("3_wide", [
        (1000000000, 50, 3, 50), (1000000000, 50, 50, 3),
        (1, 50, 49, 50), (1, 49, 50, 49), (999999937, 48, 47, 46),
    ])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(200):
        principal = rng.randint(1, 1000000000)
        years = rng.randint(1, 50)
        simple_rate = rng.randint(3, 50)
        compound_rate = rng.randint(3, 50)
        random_cases.append((principal, years, simple_rate, compound_rate))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(1000):
        principal = rng.randint(1, 1000000000)
        years = rng.randint(1, 50)
        simple_rate = rng.randint(3, 50)
        compound_rate = rng.randint(3, 50)
        io_cases.append((principal, years, simple_rate, compound_rate))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(10000, 5, 10, 15), (2000, 4, 3, 5),
                   (100, 3, 5, 4), (12345, 3, 9, 7)])
build()
