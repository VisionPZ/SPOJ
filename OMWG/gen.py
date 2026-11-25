#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def edge_count(rows, columns):
    total = 0
    for row in range(rows):
        for column in range(columns):
            if column + 1 < columns:
                total += 1
            if row + 1 < rows:
                total += 1
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    lines = []
    position = 1
    for _ in range(case_count):
        rows = tokens[position]
        columns = tokens[position + 1]
        position += 2
        lines.append(str(edge_count(rows, columns)))
    return "\n".join(lines) + "\n"


SAMPLE = """1
2 2
"""
SAMPLE_OUT = """4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0\n") == "0\n"
assert oracle("1\n1 1\n") == "0\n"
assert oracle("1\n1 1000\n") == "999\n"
assert oracle("1\n3 4\n") == "17\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(f"{rows} {columns}\n" for rows, columns in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0), (0, 5), (5, 0), (1, 1), (1, 10), (10, 1)])
    write("3_wide", [(1000, 1000), (1000, 0), (0, 1000), (1, 1000)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(0, 1000), rng.randint(0, 1000)) for _ in range(100)])
    write("5_io", [(1000, 1000) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 2)])
build()
