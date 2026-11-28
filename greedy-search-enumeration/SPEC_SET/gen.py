#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_one(universe_size, forbid_factor):
    if forbid_factor == 1:
        return 0
    taken = set()
    answer = 0
    start = 1
    while start <= universe_size:
        if start in taken:
            start += 1
            continue
        current = start
        while current <= universe_size:
            taken.add(current)
            current *= forbid_factor
        inside = 0
        outside = 0
        current = start
        while current <= universe_size:
            inside, outside = outside + 1, max(inside, outside)
            current *= forbid_factor
        answer += max(inside, outside)
        start += 1
    return answer


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        answers.append(str(oracle_one(tokens[cursor], tokens[cursor + 1])))
        cursor += 2
    return "\n".join(answers) + "\n"


SAMPLE = """1
6 2
"""
SAMPLE_OUT = """4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_one(1, 1) == 0
assert oracle_one(10, 2) == 6
assert oracle_one(25, 5) == 21
assert oracle_one(1000, 1000) == 999


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{universe_size} {forbid_factor}\n"
        for universe_size, forbid_factor in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, 1), (1, 2), (2, 2), (5, 10),
                      (100, 1), (100, 100000000)])
    rng = random.Random(20261126)
    write("3_wide", [(rng.randint(1, 5000), rng.randint(2, 100))
                     for _ in range(150)])
    write("4_random", [(rng.randint(1, 3000), rng.randint(2, 3000))
                       for _ in range(200)])
    write("5_io", [(rng.randint(1, 6), rng.randint(1, 5))
                   for _ in range(100000)])
    big = [(rng.randint(1, 100000000), rng.randint(1, 100000000))
           for _ in range(100000)]
    Path("/tmp/SPEC_SET_big.txt").write_text(
        str(len(big)) + "\n" + "".join(
            f"{universe_size} {forbid_factor}\n"
            for universe_size, forbid_factor in big))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(6, 2)])
build()
