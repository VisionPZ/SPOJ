#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ROWS = 5
MOD = 1000000007


def enumerate_columns(blocked_row=None):
    size = 1 << ROWS
    transitions = [[0] * size for _ in range(size)]

    def walk(row, occupied, outgoing, ways, incoming):
        if row == ROWS:
            transitions[incoming][outgoing] += ways
            return
        if (occupied >> row) & 1 or blocked_row == row:
            walk(row + 1, occupied, outgoing, ways, incoming)
            return
        walk(row + 1, occupied | (1 << row), outgoing | (1 << row), ways, incoming)
        if row + 1 < ROWS and not (occupied >> (row + 1)) & 1 and blocked_row != row + 1:
            walk(row + 2, occupied | (1 << row) | (1 << (row + 1)), outgoing, ways, incoming)

    for incoming in range(size):
        if blocked_row is not None and (incoming >> blocked_row) & 1:
            continue
        walk(0, incoming, 0, 1, incoming)
    return transitions


NORMAL = enumerate_columns()
HOLES = [enumerate_columns(row) for row in range(ROWS)]


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cases = []
    position = 1
    largest = 0
    for _ in range(case_count):
        columns = int(tokens[position])
        row = ord(tokens[position + 1]) - 65
        hole = int(tokens[position + 2])
        position += 3
        cases.append((columns, row, hole))
        largest = max(largest, columns)

    size = 1 << ROWS
    vectors = [[0] * size for _ in range(largest + 1)]
    vectors[0][0] = 1
    for exponent in range(1, largest + 1):
        previous = vectors[exponent - 1]
        current = vectors[exponent]
        for outgoing in range(size):
            total = sum(previous[incoming] * NORMAL[incoming][outgoing]
                        for incoming in range(size))
            current[outgoing] = total % MOD

    answers = []
    for columns, row, hole in cases:
        left = vectors[hole - 1]
        right = vectors[columns - hole]
        hole_matrix = HOLES[row]
        total = sum(left[incoming] * hole_matrix[incoming][outgoing] * right[outgoing]
                    for incoming in range(size) for outgoing in range(size))
        answers.append(str(total % MOD))
    return "\n".join(answers) + "\n"


SAMPLE = """3
1 C 1
3 B 2
5 A 1
"""
SAMPLE_OUT = """1
8
192
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 E 1\n") == "1\n"
assert oracle("1\n3 D 3\n") == "0\n"
assert oracle("1\n5 C 1\n") == "192\n"
assert oracle("1\n5 C 3\n") == "196\n"


def write(name, cases):
    lines = [str(len(cases))]
    for columns, row, hole in cases:
        lines.append(f"{columns} {chr(65 + row)} {hole}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 0, 1), (1, 4, 1), (3, 1, 2), (3, 3, 2), (5, 2, 1), (5, 2, 3),
    ])
    write("3_wide", [
        (20000, 0, 1), (20000, 2, 10000), (19999, 4, 19999), (20000, 1, 19999),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(100):
        columns = rng.randint(1, 20000)
        cases.append((columns, rng.randint(0, 4), rng.randint(1, columns)))
    write("4_random", cases)
    cases = []
    for _ in range(40000):
        columns = rng.randint(1, 20000)
        cases.append((columns, rng.randint(0, 4), rng.randint(1, columns)))
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
