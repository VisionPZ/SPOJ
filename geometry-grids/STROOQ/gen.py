#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RESIDUES = [value for value in range(1000) if pow(value, 3, 1000) == 888]


def count_upto(limit):
    blocks = (limit + 1) // 1000
    remainder = (limit + 1) % 1000
    return blocks * len(RESIDUES) + sum(residue < remainder for residue in RESIDUES)


def kth_number(rank):
    low, high = 0, 1 << 63
    while low < high:
        middle = (low + high) // 2
        if count_upto(middle) >= rank:
            high = middle
        else:
            low = middle + 1
    return low


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = [str(kth_number(int(tokens[index + 1]))) for index in range(case_count)]
    return "\n".join(answers) + "\n"


SAMPLE = """1
1
"""
SAMPLE_OUT = """192
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert RESIDUES == [192, 442, 692, 942]
assert oracle("2\n1\n2\n") == "192\n442\n"
assert oracle("1\n11\n") == "2692\n"
assert pow(942, 3, 1000) == 888


def write(name, ranks):
    text = "\n".join([str(len(ranks))] + [str(rank) for rank in ranks]) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 8, 100])
    write("3_wide", [2000000000000, 1999999999999, 1000000000000,
                     999999999999, 1234567890123])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 2000000000000) for _ in range(1000)])
    write("5_io", [rng.randint(1, 2000000000000) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1])
build()
