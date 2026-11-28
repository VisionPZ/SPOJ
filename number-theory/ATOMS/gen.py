#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_VALUE = 10 ** 18


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        atoms = tokens[cursor]
        factor = tokens[cursor + 1]
        limit = tokens[cursor + 2]
        cursor += 3
        low = 0
        high = 64
        while low < high:
            middle = (low + high + 1) // 2
            if atoms * pow(factor, middle) <= limit:
                low = middle
            else:
                high = middle - 1
        answers.append(str(low))
    return "\n".join(answers) + "\n"


def brute(natoms, factor, limit):
    elapsed = 0
    while natoms * factor <= limit:
        natoms *= factor
        elapsed += 1
    return elapsed


SAMPLE = """2
2 2 7
2 2 8
"""
SAMPLE_OUT = """1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 2 7\n") == "1\n"
assert oracle("1\n2 2 8\n") == "2\n"
assert oracle("1\n2 2 1\n") == "0\n"
assert oracle("1\n1000000000000000000 2 1000000000000000000\n") == "0\n"
assert brute(2, 2, 7) == 1 and brute(2, 2, 8) == 2 and brute(3, 3, 100) == 3


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{atoms} {factor} {limit}\n" for atoms, factor, limit in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, 2, 1), (2, 2, 2), (2, 2, 3), (3, 3, 8), (10, 10, 1000000000000000000)])
    write("3_wide", [(2, 2, MAX_VALUE), (3, 2, MAX_VALUE),
                     (MAX_VALUE, 2, MAX_VALUE), (2, MAX_VALUE, MAX_VALUE)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(2, MAX_VALUE), rng.randint(2, 10 ** 9),
                        rng.randint(2, MAX_VALUE)) for _ in range(200)])
    write("5_io", [(rng.randint(2, 10 ** 6), rng.randint(2, 100),
                    rng.randint(2, MAX_VALUE)) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 2, 7), (2, 2, 8)])
build()
