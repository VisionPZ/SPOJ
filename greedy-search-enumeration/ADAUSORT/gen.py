#!/usr/bin/env python3
import random
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        element_count = tokens[cursor]; cursor += 1
        values = tokens[cursor:cursor + element_count]; cursor += element_count
        groups = defaultdict(list)
        for position, value in enumerate(values, 1):
            groups[value].append(position)
        ordering = []
        for value in sorted(groups):
            ordering.extend(reversed(groups[value]))
        answers.append(" ".join(map(str, ordering)))
    return "\n".join(answers) + "\n"


SAMPLE = """4
1 2 3 4
"""
SAMPLE_OUT = """1 2 3 4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n3 2 1\n") == "3 2 1\n"
assert oracle("6\n6 6 6 6 6 6\n") == "6 5 4 3 2 1\n"
assert oracle("5\n5 5 2 2 3\n") == "4 3 5 2 1\n"
assert oracle("6\n1 2 1 2 1 2\n") == "5 3 1 6 4 2\n"
assert oracle("1\n7\n") == "1\n"


def write(name, cases):
    text = "".join(f"{len(values)}\n" + " ".join(map(str, values)) + "\n" for values in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[1, 1, 1], [3, 2, 1], [1, 2, 3], [2, 2, 1, 1], [7]])
    rng = random.Random(20261126)
    write("3_wide", [[42] * 100000])
    write("4_random", [[rng.randint(1, 100000) for _ in range(5000)] for _ in range(3)])
    write("5_io", [[rng.randint(1, 100000) for _ in range(100000)]])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[1, 2, 3, 4]])
build()
