#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_pair(rank):
    odd_term = 7
    hypotenuse = 5
    for _ in range(rank - 1):
        odd_term, hypotenuse = 3 * odd_term + 4 * hypotenuse, 2 * odd_term + 3 * hypotenuse
    return (odd_term - 1) // 2, hypotenuse


def oracle(text):
    tokens = text.split()
    cursor = 0
    cases = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(cases):
        rank = int(tokens[cursor]); cursor += 1
        modulus = int(tokens[cursor]); cursor += 1
        leg, hypotenuse = oracle_pair(rank)
        answers.append(f"{leg % modulus} {hypotenuse % modulus}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
1 10
2 123
4 289
"""
SAMPLE_OUT = """3 5
20 29
118 118
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_pair(1) == (3, 5)
assert oracle_pair(3) == (119, 169)
assert oracle("1\n4 289\n") == "118 118\n"
assert oracle("1\n1 5\n") == "3 0\n"
assert oracle("1\n2 6\n") == "2 5\n"


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{rank} {modulus}\n" for rank, modulus in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 2), (1, 5), (2, 6), (3, 1), (4, 2), (5, 1000000000),
    ])
    write("3_wide", [(rank, 1000000000) for rank in range(1, 60)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 300), rng.randint(2, 1000000000))
                       for _ in range(200)])
    write("5_io", [(rng.randint(1, 200), rng.randint(2, 1000000000))
                   for _ in range(5000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
print("first legs:", [oracle_pair(rank) for rank in range(1, 5)])
