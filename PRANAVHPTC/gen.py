#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    test_count = tokens[0]
    position = 1
    answers = []
    for _ in range(test_count):
        seats = tokens[position]
        start = (tokens[position + 1] - 1) % seats + 1
        target = (tokens[position + 2] - 1) % seats + 1
        position += 3

        forward = 0
        walker = start
        while walker != target and forward <= seats:
            walker = walker % seats + 1
            forward += 1

        backward = 0
        walker = start
        while walker != target and backward <= seats:
            walker = (walker - 2) % seats + 1
            backward += 1

        answers.append(str(min(forward, backward)))
    return "\n".join(answers) + "\n"


SAMPLE = """4
9 1 3
8 4 5
5 1 2
8 2 4
"""
SAMPLE_OUT = """2
1
1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1 2\n") == "1\n"
assert oracle("1\n5 3 3\n") == "0\n"
assert oracle("1\n9 1 9\n") == "1\n"
assert oracle("1\n10 1 6\n") == "5\n"


def write(name, triples):
    text = str(len(triples)) + "\n" + "\n".join(
        " ".join(str(value) for value in triple) for triple in triples
    ) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1, 1, 1], [2, 1, 2], [3, 1, 3], [1000, 500, 500]])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(1, 5000), rng.randint(1, 5000), rng.randint(1, 5000)] for _ in range(200)])
    write("4_random", [[rng.randint(1, 2000), rng.randint(1, 2000), rng.randint(1, 2000)] for _ in range(100)])
    write("5_io", [[rng.randint(1, 500), rng.randint(1, 500), rng.randint(1, 500)] for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
