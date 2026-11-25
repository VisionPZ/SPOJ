#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007

TRANSITION = [[0] * 4 for _ in range(4)]
for first_flag in range(2):
    for second_flag in range(2):
        state = first_flag * 2 + second_flag
        TRANSITION[state][state] = (TRANSITION[state][state] + 2) % MOD
        TRANSITION[second_flag + 2][state] = (TRANSITION[second_flag + 2][state] + 1) % MOD
        TRANSITION[first_flag * 2 + 1][state] = (TRANSITION[first_flag * 2 + 1][state] + 1) % MOD


def multiply(left, right):
    result = [[0] * 4 for _ in range(4)]
    for row in range(4):
        for middle in range(4):
            factor = left[row][middle]
            if factor:
                for column in range(4):
                    result[row][column] = (result[row][column] + factor * right[middle][column]) % MOD
    return result


@lru_cache(maxsize=None)
def answer_for(size):
    power = [[1 if row == column else 0 for column in range(4)] for row in range(4)]
    base = TRANSITION
    exponent = size
    while exponent:
        if exponent & 1:
            power = multiply(power, base)
        base = multiply(base, base)
        exponent >>= 1
    return power[3][0]


def oracle(text):
    tokens = [int(value) for value in text.split()]
    values = tokens[1:1 + tokens[0]]
    return "".join(str(answer_for(value)) + "\n" for value in values)


SAMPLE = """2
4
8
"""
SAMPLE_OUT = """110
52670
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "0\n"
assert oracle("1\n2\n") == "2\n"
assert oracle("1\n3\n") == "18\n"
assert answer_for(1000000) == 217417329


def write(name, values):
    text = str(len(values)) + "\n" + "".join(str(value) + "\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [1000000, 999999, 999998, 999997])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000) for _ in range(100)])
    write("5_io", [rng.randint(1, 1000000) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [4, 8])
build()
