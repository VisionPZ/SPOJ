#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = iter(text.split())
    case_count = int(next(tokens))
    answers = []
    for _ in range(case_count):
        count = int(next(tokens))
        values = [int(next(tokens)) for _ in range(count)]
        best = max((len(list(group)) for _, group in itertools.groupby(values)), default=0)
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = "1\n5\n1 1 1 2 2\n"
SAMPLE_OUT = "3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n7\n") == "1\n"
assert oracle("1\n4\n-1 -1 -1 -1\n") == "4\n"
assert oracle("1\n5\n1 -1 1 -1 1\n") == "1\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for values in cases:
        text += str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1], [2, 2], [3, 1, 1], [-1, -1, -1, -1], [10 ** 18, -(10 ** 18)]])
    write("3_wide", [[1000000000000000000] * 100000])
    rng = random.Random(20261126)
    write("4_random", [[rng.randint(-10 ** 18, 10 ** 18) for _ in range(rng.randint(1, 100))] for _ in range(50)])
    write("5_io", [[1] * 100000])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[1, 1, 1, 2, 2]])
build()
