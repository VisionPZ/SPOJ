#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def feasible(team_count, experienced, newbies):
    first_type = max(0, 2 * team_count - experienced)
    last_type = min(team_count, newbies - team_count)
    return first_type <= last_type


def oracle_case(experienced, newbies):
    low = 0
    high = min(experienced, newbies)
    while low < high:
        middle = (low + high + 1) // 2
        if feasible(middle, experienced, newbies):
            low = middle
        else:
            high = middle - 1
    return low


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for case_index in range(case_count):
        experienced = tokens[1 + 2 * case_index]
        newbies = tokens[2 + 2 * case_index]
        answers.append(str(oracle_case(experienced, newbies)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
2 6
4 5
"""
SAMPLE_OUT = """2
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n8 0\n") == "0\n"
assert oracle("1\n0 8\n") == "0\n"
assert oracle("1\n1 1\n") == "0\n"
assert oracle("1\n500000 500000\n") == "333333\n"


def write(name, pairs):
    text = str(len(pairs)) + "\n"
    text += "".join(f"{experienced} {newbies}\n" for experienced, newbies in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0), (8, 0), (0, 8), (1, 1), (3, 3), (2, 1)])
    write("3_wide", [(500000, 500000), (1, 500000), (500000, 1),
                     (499999, 500000)])
    rng = random.Random(20261126)
    pairs = [(rng.randint(0, 500000), rng.randint(0, 500000))
             for _ in range(40)]
    write("4_random", pairs)
    pairs = [(500000, 500000) for _ in range(10)]
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 6), (4, 5)])
build()