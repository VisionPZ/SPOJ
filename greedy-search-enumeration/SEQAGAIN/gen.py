#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_total = tokens[0]
    pos = 1
    lines = []
    for _ in range(case_total):
        first_seed, second_seed, term_index, factor = tokens[pos:pos + 4]
        pos += 4
        if term_index == 0:
            answer = first_seed % MOD
        elif term_index == 1:
            answer = second_seed % MOD
        elif factor == 0:
            answer = 1
        else:
            previous = first_seed % MOD
            current = second_seed % MOD
            for _ in range(2, term_index + 1):
                previous, current = current, pow(current * previous, factor, MOD)
            answer = current
        lines.append(str(answer))
    return "\n".join(lines) + "\n"


SAMPLE = """1
1 1 2 1
"""
SAMPLE_OUT = """1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 3 0 7\n") == "2\n"
assert oracle("1\n2 3 1 7\n") == "3\n"
assert oracle("1\n5 7 4 0\n") == "1\n"
assert oracle("1\n0 9 5 3\n") == "0\n"
assert oracle("1\n2 3 3 2\n") == str(pow(pow(6, 2, MOD) * 3, 2, MOD)) + "\n"
assert pow(2, 1000000006, MOD) == 1


def write(name, cases):
    text = str(len(cases)) + "\n"
    for first_seed, second_seed, term_index, factor in cases:
        text += "%d %d %d %d\n" % (first_seed, second_seed, term_index, factor)
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    write("2_edges", [
        (0, 0, 0, 1), (0, 0, 1, 1), (1, 1, 2, 0), (7, 11, 30, 1), (0, 5, 12, 2),
    ])
    rng = random.Random(20261126)
    write("3_wide", [
        (rng.randint(0, 1000000), rng.randint(0, 1000000), rng.randint(2, 80),
         rng.randint(0, 1000000000))
        for _ in range(200)
    ])
    write("4_random", [
        (rng.randint(0, 1000000), rng.randint(0, 1000000), rng.randint(2, 40),
         rng.randint(0, 1000000000))
        for _ in range(50)
    ])
    write("5_io", [
        (rng.randint(100000, 1000000), rng.randint(100000, 1000000), rng.randint(5, 20),
         rng.randint(1, 1000000000))
        for _ in range(5000)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
