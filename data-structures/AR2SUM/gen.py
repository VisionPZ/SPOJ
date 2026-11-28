#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    rows, columns = tokens[0], tokens[1]
    values = tokens[2:2 + rows * columns]
    matrix = [values[row * columns:(row + 1) * columns] for row in range(rows)]
    return str(sum(sum(row) for row in matrix)) + "\n"


SAMPLE = """2 3
1 2 3
4 5 6
"""
SAMPLE_OUT = """21
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 3\n4 5 6\n") == "15\n"
assert oracle("3 1\n7\n8\n9\n") == "24\n"
assert oracle("2 2\n0 0\n0 0\n") == "0\n"


def write(name, text, expected=None):
    if expected is None:
        expected = oracle(text)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def matrix_text(rows, columns, values):
    return f"{rows} {columns}\n" + " ".join(str(value) for value in values) + "\n"


def build():
    write("2_edges", matrix_text(1, 1, [0]))
    write("3_wide", matrix_text(3, 3, [1000000000] * 9))
    rng = random.Random(20261126)
    write("4_random", matrix_text(8, 12, [rng.randint(0, 100000) for _ in range(96)]))
    write("5_io", matrix_text(100, 100, [rng.randint(0, 1000000) for _ in range(10000)]))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE, SAMPLE_OUT)
build()
