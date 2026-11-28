#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TABLE_MAX = 2000
FINAL_TABLE = {}
for value in range(-4, TABLE_MAX + 1):
    if value < 0:
        FINAL_TABLE[value] = value
    else:
        FINAL_TABLE[value] = min(FINAL_TABLE[value - 3], FINAL_TABLE[value - 4])
assert all(FINAL_TABLE[value] == -4 for value in range(6, TABLE_MAX + 1))


def best_final(section_value):
    if section_value < 0:
        return section_value
    if section_value <= TABLE_MAX:
        return FINAL_TABLE[section_value]
    return -4


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        section_count = tokens[cursor]
        cursor += 1
        values = tokens[cursor:cursor + section_count]
        cursor += section_count
        answers.append(" ".join(str(best_final(value)) for value in values))
    return "\n".join(answers) + "\n"


SAMPLE = "2\n3\n0 2 1\n4\n3 2 1 -1\n"
SAMPLE_OUT = "-4 -2 -3\n-4 -2 -3 -1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n6\n0 1 2 3 4 5\n") == "-4 -3 -2 -4 -4 -3\n"
assert oracle("1\n4\n-1 -2 -1000000000 1000000000\n") == "-1 -2 -1000000000 -4\n"
assert best_final(6) == -4
assert best_final(-7) == -7


def write(name, cases):
    lines = [str(len(cases))]
    for values in cases:
        lines.append(str(len(values)))
        lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [0, 1, 2, 3, 4, 5, 6],
        [-1, -2, -1000000000, 1000000000],
        [1],
        [0],
        [-1000000000],
        [5, 8, 9, 11, 13],
    ])
    write("3_wide", [list(range(0, 1000)) * 100])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(10):
        random_cases.append([rng.randint(-1000000000, 1000000000) for _ in range(10000)])
    write("4_random", random_cases)
    write("5_io", [[rng.randint(-1000, 1000) for _ in range(100000)]])


def trace():
    values = [0, 2, 1, 3, 2, 1, -1]
    print("section values:", values)
    for value in values:
        print(f"{value:>3} -> {best_final(value)}")
    print("final line:", " ".join(str(best_final(value)) for value in values))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
trace()
