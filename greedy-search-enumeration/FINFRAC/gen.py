#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    answers = []
    for offset in range(0, len(tokens), 4):
        low_num, low_den, high_num, high_den = tokens[offset:offset + 4]
        assert low_num * high_den < high_num * low_den
        denominator = 1
        while True:
            min_numerator = (low_num * denominator) // low_den + 1
            max_numerator = (high_num * denominator - 1) // high_den
            if min_numerator <= max_numerator:
                answers.append(f"{min_numerator}/{denominator}")
                break
            denominator += 1
    return "\n".join(answers) + "\n"


SAMPLE = """1 3 1 2
2 1 3 1
2 1 4 1
1000 1001 1001 1002
"""
SAMPLE_OUT = """2/5
5/2
3/1
2001/2003
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 2 2 3\n") == "3/5\n"
assert oracle("1 1000 1 999\n") == "2/1999\n"
assert oracle("7 10 4 5\n") == "3/4\n"
assert oracle("1 7 1 6\n") == "2/13\n"


def write(name, cases):
    text = "\n".join(f"{low_num} {low_den} {high_num} {high_den}"
                     for low_num, low_den, high_num, high_den in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 5, 1, 4), (1, 10, 1, 9), (1, 2, 99, 100),
                      (7, 10, 4, 5), (1, 1000, 1, 999)])
    write("3_wide", [(500, 1000, 501, 1000), (999, 1000, 1, 1),
                     (1, 1000, 999, 1000), (1234, 2000, 1235, 2000)])
    rng = random.Random(20261126)
    cases = []
    for _ in range(60):
        low_num = rng.randint(1, 1000)
        low_den = rng.randint(1, 1000)
        high_num = rng.randint(1, 1000)
        high_den = rng.randint(1, 1000)
        if low_num * high_den >= high_num * low_den:
            low_num, low_den, high_num, high_den = 1, 1000, 999, 1000
        cases.append((low_num, low_den, high_num, high_den))
    write("4_random", cases)
    io_cases = [(case_index + 1, 2000, case_index + 2, 2000)
                for case_index in range(500)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
