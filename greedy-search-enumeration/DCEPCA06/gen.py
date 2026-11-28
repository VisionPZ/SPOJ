#!/usr/bin/env python3
import random
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle_case(length, gap):
    state = [0] * 10
    for digit in range(1, 10):
        state[digit] = 1
    for _ in range(length - 1):
        updated = [0] * 10
        for previous in range(10):
            for next_digit in range(10):
                if abs(previous - next_digit) >= gap:
                    updated[next_digit] = (updated[next_digit] + state[previous]) % MODULUS
        state = updated
    return str(sum(state) % MODULUS)


def oracle(text):
    tokens = [int(token) for token in text.split()]
    case_count = tokens[0]
    answers = []
    position = 1
    for _ in range(case_count):
        answers.append(oracle_case(tokens[position], tokens[position + 1]))
        position += 2
    return "\n".join(answers) + "\n"


SAMPLE = """2
2 9
2 8
"""
SAMPLE_OUT = """1
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 0\n") == str(9 * 10) + "\n"
assert oracle("1\n3 0\n") == str(9 * 100) + "\n"
assert oracle("1\n2 9\n") == "1\n"
assert oracle("1\n2 8\n") == "4\n"
for gap in range(10):
    for length in range(1, 7):
        brute = sum(
            1 for digits in product(range(10), repeat=length)
            if digits[0] != 0 and all(abs(digits[i] - digits[i + 1]) >= gap
                                      for i in range(length - 1)))
        assert oracle_case(length, gap) == str(brute), (length, gap)


def write(name, pairs):
    text = f"{len(pairs)}\n" + "\n".join(f"{length} {gap}" for length, gap in pairs) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(2, 0), (2, 9), (2, 8), (3, 9), (4, 9), (5, 0)])
    write("3_wide", [(1000, gap) for gap in range(10)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(2, 1000), rng.randint(0, 9)) for _ in range(20)])
    write("5_io", [(rng.randint(500, 1000), rng.randint(0, 9)) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 9), (2, 8)])
build()
