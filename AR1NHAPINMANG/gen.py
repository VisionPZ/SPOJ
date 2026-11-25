#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    row_count = int(tokens[0])
    column_count = int(tokens[1])
    values = tokens[2:2 + row_count * column_count]
    rows = []
    cursor = 0
    for _ in range(row_count):
        rows.append("\t".join(values[cursor:cursor + column_count]))
        cursor += column_count
    return "\n".join(rows) + "\n"


SAMPLE = "2 3\n1 2 3\n4 5 6\n"
SAMPLE_OUT = "1\t2\t3\n4\t5\t6\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n7\n") == "7\n"
assert oracle("1 4\n5 6 7 8\n") == "5\t6\t7\t8\n"
assert oracle("3 2\n1 2\n3 4\n5 6\n") == "1\t2\n3\t4\n5\t6\n"


def write(name, row_count, column_count, values):
    lines = [f"{row_count} {column_count}"]
    cursor = 0
    for _ in range(row_count):
        lines.append(" ".join(str(value) for value in
                              values[cursor:cursor + column_count]))
        cursor += column_count
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, [0])
    write("3_wide", 1, 5, [2147483647, 2147483646, 1000000000,
                           999999999, 42])
    rng = random.Random(20261126)
    write("4_random", 7, 6,
          [rng.randint(0, 10 ** 9) for _ in range(42)])
    write("5_io", 120, 200,
          [rng.randint(0, 10 ** 9) for _ in range(24000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
