#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1908


def catalan_mod(tree_count):
    return math.comb(2 * tree_count, tree_count) // (tree_count + 1) % MODULUS


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = [catalan_mod(tokens[index + 1]) for index in range(case_count)]
    return "".join(str(answer) + "\n" for answer in answers)


SAMPLE = """2
1
2
"""
SAMPLE_OUT = """1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert catalan_mod(0) == 1
assert catalan_mod(3) == 5
assert catalan_mod(5) == 42
assert catalan_mod(10) == 1532
assert catalan_mod(1000) == 212


def write(name, tree_counts):
    text = str(len(tree_counts)) + "\n" + "".join(str(value) + "\n" for value in tree_counts)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 1000])
    rng = random.Random(20261126)
    write("3_wide", [1000] * 1000)
    write("4_random", [rng.randint(1, 1000) for _ in range(1000)])
    write("5_io", [rng.choice([998, 999, 1000]) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2])
build()
