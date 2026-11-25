#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def solve_case(rows):
    balls = [(row + 1, column + 1) for row in range(len(rows)) for column in range(row + 1)]
    best = 0
    for mask in range(1 << len(balls)):
        chosen = {balls[index] for index in range(len(balls)) if mask >> index & 1}
        valid = True
        for row, column in chosen:
            for parent in ((row - 1, column - 1), (row - 1, column)):
                if parent[0] >= 1 and 1 <= parent[1] <= parent[0] and parent not in chosen:
                    valid = False
                    break
            if not valid:
                break
        if valid:
            total = sum(rows[row - 1][column - 1] for row, column in chosen)
            if total > best:
                best = total
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        row_count = tokens[cursor]
        cursor += 1
        if row_count == 0:
            break
        rows = []
        for _ in range(row_count):
            rows.append(tokens[cursor:cursor + len(rows) + 1])
            cursor += len(rows[-1])
        answers.append(str(solve_case(rows)))
    return "\n".join(answers) + "\n"


SAMPLE = """4
3
-5 3
-8 2 -8
3 9 -2 7
2
-2
1 -10
3
1
-5 3
6 -4 1
0
"""
SAMPLE_OUT = "7\n0\n6\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5\n1\n-3\n0\n") == "5\n0\n"
assert oracle("2\n-1\n2 3\n0\n") == "4\n"
assert oracle("3\n1\n-5 3\n6 -4 1\n0\n") == "6\n"
assert solve_case([[4], [5, 6]]) == 15


def encode(rows_list):
    parts = []
    for rows in rows_list:
        parts.append(str(len(rows)))
        for row in rows:
            parts.append(" ".join(str(value) for value in row))
    parts.append("0")
    return "\n".join(parts) + "\n"


def write(name, rows_list):
    text = encode(rows_list)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[[-7]], [[2, 3]], [[-1], [-2, -3]], [[0, 0], [0, 0, 0]]])
    write("3_wide", [[[-100000],
                      [100000, -100000],
                      [-100000, 100000, -100000],
                      [100000, -100000, 100000, -100000],
                      [-100000, 100000, -100000, 100000, -100000]]])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(12):
        size = rng.randint(1, 5)
        random_cases.append([[rng.randint(-100000, 100000) for _ in range(row + 1)]
                             for row in range(size)])
    write("4_random", random_cases)
    io_cases = []
    for _ in range(400):
        size = rng.randint(1, 5)
        io_cases.append([[rng.randint(-9, 9) for _ in range(row + 1)]
                         for row in range(size)])
    write("5_io", io_cases)
    stress = [1000] + [rng.randint(-100000, 100000) for _ in range(500500)]
    Path("/tmp/BALLLSTA_big.txt").write_text(" ".join(str(value) for value in stress) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[[3], [-5, 3], [-8, 2, -8], [3, 9, -2, 7]],
                   [[-2], [1, -10]],
                   [[1], [-5, 3], [6, -4, 1]]])
build()
