#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        left = tokens[cursor:cursor + 4]
        right = tokens[cursor + 4:cursor + 8]
        cursor += 8
        lookup = {color: position + 1 for position, color in enumerate(right)}
        answers.append(" ".join(str(lookup.get(color, 0)) for color in left))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n1 3 4 2\n2 4 3 1\n1 2 3 4\n1 2 3 4\n"
SAMPLE_OUT = "4 3 2 1\n1 2 3 4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4 3 2 1\n4 3 2 1\n") == "1 2 3 4\n"
assert oracle("1\n2 2 2 2\n1 2 3 4\n") == "2 2 2 2\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        " ".join(str(value) for value in left) + "\n" + " ".join(str(value) for value in right) + "\n"
        for left, right in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([1, 2, 3, 4], [4, 3, 2, 1]), ([2, 2, 2, 2], [1, 2, 3, 4])])
    write("3_wide", [([1, 2, 3, 4], [4, 3, 2, 1])] * 20)
    rng = random.Random(20261126)
    cases = []
    for _ in range(20):
        left = [rng.randint(1, 4) for _ in range(4)]
        right = [rng.randint(1, 4) for _ in range(4)]
        cases.append((left, right))
    write("4_random", cases)
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([1, 3, 4, 2], [2, 4, 3, 1]), ([1, 2, 3, 4], [1, 2, 3, 4])])
build()
