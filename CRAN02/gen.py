#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_total = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_total):
        element_total = tokens[cursor]
        cursor += 1
        values = tokens[cursor:cursor + element_total]
        cursor += element_total
        zero_count = 0
        for left in range(element_total):
            running = 0
            for right in range(left, element_total):
                running += values[right]
                if running == 0:
                    zero_count += 1
        answers.append(str(zero_count))
    return "\n".join(answers) + "\n"


SAMPLE = """2
4
0 1 -1 0
6
5 2 -2 5 -5 9
"""
SAMPLE_OUT = """6
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n0\n") == "1\n"
assert oracle("1\n3\n1 2 3\n") == "0\n"
assert oracle("1\n4\n0 1 -1 0\n") == "6\n"


def render(cases):
    parts = [str(len(cases))]
    for values in cases:
        parts.append(str(len(values)))
        parts.append(" ".join(str(value) for value in values))
    return "\n".join(parts) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1], [0], [1, -1], [0, 0, 0], [-10, 10, 0, 5, -5]])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(-10, 10) for _ in range(300)]])
    write("4_random", [[rng.randint(-10, 10) for _ in range(rng.randint(1, 200))]
                       for _ in range(3)])
    write("5_io", [[rng.randint(-10, 10) for _ in range(300)] for _ in range(5)])
    big = random.Random(9182736)
    huge = [big.randint(-10, 10) for _ in range(1000000)]
    Path("/tmp/CRAN02_big.txt").write_text(render([huge]))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[0, 1, -1, 0], [5, 2, -2, 5, -5, 9]])
build()
