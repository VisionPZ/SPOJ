#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    lines = []
    for _ in range(case_count):
        count = tokens[position]
        values = tokens[position + 1:position + 1 + count]
        position += 1 + count
        lines.append(str(sum(1 for value in values if 2 * value in values)))
    return "\n".join(lines) + "\n"


SAMPLE = """2
7
1 3 4 7 9 2 18
3
1 4 3
"""
SAMPLE_OUT = """3
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4\n0 0 0 0\n") == "4\n"
assert oracle("1\n1\n0\n") == "1\n"
assert oracle("1\n3\n-3 -6 4\n") == "1\n"
assert oracle("1\n2\n1 2\n") == "1\n"


def write(name, cases):
    parts = [str(len(cases))]
    for values in cases:
        parts.append(str(len(values)))
        parts.append(" ".join(str(value) for value in values))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0], [0, 0, 0, 0], [-5, -10, 5, 10], [10000], [-10000],
                      [1, 2, 4, 8, 16], [3, 6, 12], [-1, -2, 0]])
    write("3_wide", [([10000, -10000, 0] * 333)[:1000],
                     list(range(-500, 500)),
                     [value * 2 for value in range(-400, 400)] + [0]])
    rng = random.Random(20261126)
    write("4_random", [[rng.randint(-10000, 10000) for _ in range(rng.randint(1, 1000))]
                       for _ in range(100)])
    pool = [0, 1, 2, 4, 8, -3, -6, 10000, -10000, 5000]
    write("5_io", [[rng.choice(pool) for _ in range(100)] for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[1, 3, 4, 7, 9, 2, 18], [1, 4, 3]])
build()
