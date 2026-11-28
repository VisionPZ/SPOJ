#!/usr/bin/env python3
import random
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007
EXPONENT_MODULUS = 1000000006


def oracle(text):
    tokens = [int(value) for value in text.split()]
    test_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(test_count):
        base_value = tokens[cursor]
        power_base = tokens[cursor + 1]
        combin_value = tokens[cursor + 2]
        cursor += 3
        binomial = comb(2 * combin_value, combin_value)
        if base_value == 0:
            answer = 1 if power_base == 0 else 0
        else:
            reduced_exponent = pow(power_base, binomial, EXPONENT_MODULUS)
            answer = pow(base_value, reduced_exponent, MODULUS)
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


SAMPLE = """1

1 1 1
"""
SAMPLE_OUT = """1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n100000 100000 100000\n") == "754901378\n"
assert oracle("1\n10 10 10\n") == "330427784\n"
assert oracle("1\n0 0 0\n") == "1\n"
assert oracle("1\n2 2 2\n") == "582344008\n"
assert comb(0, 0) == 1


def write(name, cases):
    text = str(len(cases)) + "\n" + "\n".join(" ".join(map(str, case)) for case in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (0, 0, 0), (0, 5, 3), (5, 0, 7), (1, 0, 100000),
        (1, 1, 0), (7, 3, 1), (99999, 99999, 2),
    ])
    rng = random.Random(20261126)
    wide = [(rng.randint(1, 100000), rng.randint(1, 100000), rng.randint(90000, 100000))
            for _ in range(20)]
    write("3_wide", wide)
    random_cases = [(rng.randint(0, 100000), rng.randint(0, 100000), rng.randint(0, 100000))
                    for _ in range(120)]
    write("4_random", random_cases)
    io_cases = [(rng.randint(0, 100000), rng.randint(0, 100000), rng.randint(0, 1000))
                for _ in range(1000)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
