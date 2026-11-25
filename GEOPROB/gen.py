#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        b = int(tokens[cursor])
        c = int(tokens[cursor + 1])
        d = int(tokens[cursor + 2])
        cursor += 3
        answers.append(str(2 * c - b - d))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3 8 5
10 18 12
"""
SAMPLE_OUT = """8
14
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 1 0\n") == "2\n"
assert oracle("1\n1 2 1\n") == "2\n"
assert oracle("1\n0 10 9\n") == "11\n"
assert 2 * 100 - 3 - 7 == 190


def write(name, triples):
    input_text = str(len(triples)) + "\n" + "".join(
        f"{b} {c} {d}\n" for b, c, d in triples)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def wide_triple(rng, length):
    middle = rng.randrange(1, 10 ** length)
    low_b = rng.randrange(0, middle)
    low_d = rng.randrange(0, middle)
    return low_b, middle, low_d


def build():
    write("2_edges", [(0, 1, 0), (0, 10**199, 10**199 - 1),
                      (10**199 - 1, 10**200 - 1, 0),
                      (5, 6, 5), (1, 2, 1)])
    rng = random.Random(20261126)
    write("3_wide", [wide_triple(rng, 200) for _ in range(40)])
    write("4_random", [wide_triple(rng, rng.randint(1, 200)) for _ in range(80)])
    write("5_io", [wide_triple(rng, 200) for _ in range(300)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 8, 5), (10, 18, 12)])
build()
