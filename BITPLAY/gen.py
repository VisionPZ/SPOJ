#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    pos = 1
    for _ in range(case_count):
        even_limit = tokens[pos]
        ones_budget = tokens[pos + 1]
        pos += 2
        candidate = -1
        if ones_budget >= 1:
            candidate = even_limit - 1
            while candidate >= 1:
                if bin(candidate).count("1") <= ones_budget:
                    break
                candidate -= 2
            if candidate < 1:
                candidate = -1
        answers.append(str(candidate))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """2
10 2
6 1
"""
SAMPLE_OUT = """9
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 0\n") == "-1\n"
assert oracle("1\n2 1\n") == "1\n"
assert oracle("1\n8 2\n") == "5\n"
assert oracle("1\n8 3\n") == "7\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(f"{limit} {budget}\n" for limit, budget in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 0), (2, 1), (4, 0), (4, 1), (8, 2), (8, 3)])
    write("3_wide", [(1000000000, 30)] * 100)
    rng = random.Random(20261126)
    write("4_random", [(2 * rng.randint(1, 10000), rng.randint(0, 6)) for _ in range(100)])
    write("5_io", [(2 * rng.randint(1, 10000), 30) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(10, 2), (6, 1)])
build()
