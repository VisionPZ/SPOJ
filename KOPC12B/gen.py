#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007

SAMPLE = """2
1
2
"""
SAMPLE_OUT = """1
6
"""


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    queries = [int(value) for value in tokens[cursor:cursor + case_count]]
    largest = max(queries)
    inverse = [0] * (largest + 2)
    inverse[1] = 1
    for value in range(2, largest + 2):
        inverse[value] = MOD - (MOD // value) * inverse[MOD % value] % MOD
    answers = []
    for query in queries:
        choose = 1
        total = 0
        for choose_count in range(1, query + 1):
            choose = choose * (query - choose_count + 1) % MOD
            choose = choose * inverse[choose_count] % MOD
            total = (total + choose_count * choose * choose) % MOD
        answers.append(str(total))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n2\n") == "6\n"
assert oracle("1\n3\n") == "30\n"
assert oracle("1\n10\n") == "923780\n"


def write(name, queries):
    text = str(len(queries)) + "\n" + "".join(f"{query}\n" for query in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 10])
    write("3_wide", [2000, 1999, 2000, 1998, 2000])
    rng = random.Random(20261128)
    write("4_random", [rng.randint(1, 500) for _ in range(200)])
    write("5_io", [rng.randint(1, 2000) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
