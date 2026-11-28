#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    pair_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(pair_count):
        small = int(tokens[cursor])
        big = int(tokens[cursor + 1])
        cursor += 2
        answers.append(str(math.gcd(small, big)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
2 6
10 11
"""
SAMPLE_OUT = """2
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0\n") == "0\n"
assert oracle("1\n0 100000000000000000000\n") == "100000000000000000000\n"
assert oracle("1\n40000 40000\n") == "40000\n"
assert math.gcd(6, 15) == 3


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{small} {big}\n" for small, big in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(0, 0), (0, 10**249), (1, 10**249 - 1),
                      (40000, 0), (40000, 10**249)])
    write("3_wide", [(40000, 10**249 + 40000), (39999, 10**249 - 1),
                     (2, "9" * 250)] * 4)
    rng = random.Random(20261126)
    pairs = []
    for _ in range(60):
        small = rng.randint(0, 40000)
        digits = "".join(str(rng.randint(0, 9)) for _ in range(rng.randint(1, 250)))
        if digits[0] == "0":
            digits = "1" + digits[1:]
        pairs.append((small, int(digits)))
    write("4_random", pairs)
    pairs = [(rng.randint(0, 40000), rng.randrange(1, 10**200)) for _ in range(4000)]
    write("5_io", pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 6), (10, 11)])
build()
