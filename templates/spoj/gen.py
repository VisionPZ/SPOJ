#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        first = int(tokens[cursor]); cursor += 1
        second = int(tokens[cursor]); cursor += 1
        answers.append(str(first + second))
    return "\n".join(answers) + "\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{first} {second}\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [(1, 2)]
assert oracle("1\n1 2\n") == "3\n"
assert oracle(str(len(SAMPLE)) + "\n" + "".join(
    f"{first} {second}\n" for first, second in SAMPLE)) == "3\n"


def build():
    write("2_edges", [(0, 0), (1, 0), (0, 1), (100000, 1), (1, 100000)])
    write("3_wide", [(10**9, 10**9), (999999999, 1)] * 10)

    random.seed(2026)
    write("4_random", [(random.randint(0, 10**9), random.randint(0, 10**9))
                       for _ in range(200)])
    write("5_io", [(random.randint(0, 10**9), random.randint(0, 10**9))
                   for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
