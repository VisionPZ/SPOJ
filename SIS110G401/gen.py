#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    fields = iter(text.split())
    answers = []
    for left_field in fields:
        right_field = next(fields)
        answers.append(str(int(left_field) + int(right_field)))
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """4 4
3 4
"""
SAMPLE_OUT = """8
7
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0 0\n") == "0\n"
assert oracle("5 0\n0 5\n") == "5\n5\n"
assert oracle("1000000000 1000000000\n") == "2000000000\n"
assert oracle("1 2 3 4\n") == "3\n7\n"


def write(name, pairs):
    text = "".join(f"{left} {right}\n" for left, right in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0), (5, 0), (0, 5), (5, 5)])
    write("3_wide", [(10 ** 9, 10 ** 9), (999999999, 1), (0, 10 ** 9)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(0, 10 ** 9), rng.randint(0, 10 ** 9))
                       for _ in range(100)])
    write("5_io", [(rng.randint(0, 10 ** 9), rng.randint(0, 10 ** 9))
                   for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, 4), (3, 4)])
build()
