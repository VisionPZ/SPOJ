#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """1
3
1 2 3
10 100 1000
"""
SAMPLE_OUT = """120
"""


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        count = int(tokens[cursor])
        cursor += 1
        heights = [int(value) for value in tokens[cursor:cursor + count]]
        cursor += count
        costs = [int(value) for value in tokens[cursor:cursor + count]]
        cursor += count
        best = None
        for target in sorted(set(heights)):
            total = sum(cost * abs(height - target)
                        for height, cost in zip(heights, costs))
            if best is None or total < best:
                best = total
        if best is None:
            best = 0
        answers.append(str(best))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n5\n0\n") == "0\n"
assert oracle("1\n2\n5 5\n3 7\n") == "0\n"
assert oracle("1\n2\n0 10000\n10000 0\n") == "0\n"
assert oracle("1\n3\n1 2 3\n1 1 1\n") == "2\n"


def write(name, cases):
    lines = [str(len(cases))]
    for heights, costs in cases:
        lines.append(str(len(heights)))
        lines.append(" ".join(str(value) for value in heights))
        lines.append(" ".join(str(value) for value in costs))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([0], [0]),
        ([5, 5], [3, 7]),
        ([0, 10000], [10000, 0]),
        ([1, 2], [0, 0]),
        ([10, 20, 30, 40], [1, 2, 3, 4]),
    ])
    rng = random.Random(20261127)
    write("3_wide", [([rng.randint(0, 1000) for _ in range(5000)],
                      [rng.randint(0, 10000) for _ in range(5000)])])
    random_cases = []
    for _ in range(8):
        size = rng.randint(1, 300)
        random_cases.append((
            [rng.randint(0, 10000) for _ in range(size)],
            [rng.randint(0, 10000) for _ in range(size)],
        ))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(15):
        size = 1000
        io_cases.append((
            [rng.choice([0, 10000]) for _ in range(size)],
            [rng.choice([0, 10000]) for _ in range(size)],
        ))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
