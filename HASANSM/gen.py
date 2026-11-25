#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        budget, milk_price, kitkat_price = tokens[position:position + 3]
        position += 3
        kitkat_cost = 7 * kitkat_price
        best = budget
        for packs in range(budget // kitkat_cost + 1):
            remainder = (budget - kitkat_cost * packs) % milk_price
            if remainder < best:
                best = remainder
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """3
150 30 35
167 40 35
99999989 31 31
"""
SAMPLE_OUT = """0
7
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n100 30 35\n") == "10\n"
assert oracle("1\n210 30 35\n") == "0\n"
assert oracle("1\n245 30 35\n") == "0\n"
assert oracle("1\n167 40 35\n") == "7\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    text += "\n".join(f"{budget} {milk} {kitkat}" for budget, milk, kitkat in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 30, 30), (100, 30, 30), (210, 30, 35)])
    write("3_wide", [(30000000000, 10000000000, 10000000000),
                     (30000000000, 30, 1000000000)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 1000000), rng.randint(30, 100),
                        rng.randint(30, 100)) for _ in range(5)])
    write("5_io", [(rng.randint(1, 100000), rng.randint(30, 60),
                    rng.randint(30, 60)) for _ in range(25)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(150, 30, 35), (167, 40, 35), (99999989, 31, 31)])
build()
