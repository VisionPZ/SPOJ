#!/usr/bin/env python3
import random
from functools import lru_cache
from itertools import product
from math import gcd
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle_case(matrix):
    row_count = len(matrix)
    col_count = len(matrix[0])
    answer = INF
    for row_target in range(col_count + 1):
        if (row_count * row_target) % col_count:
            continue
        col_target = row_count * row_target // col_count
        patterns = [pattern for pattern in product((0, 1), repeat=col_count)
                    if sum(pattern) == row_target]

        @lru_cache(maxsize=None)
        def search(row_index, columns):
            if row_index == row_count:
                return 0 if all(value == col_target for value in columns) else INF
            best = INF
            for pattern in patterns:
                updated = tuple(columns[index] + pattern[index] for index in range(col_count))
                if any(value > col_target for value in updated):
                    continue
                cost = sum(matrix[row_index][index] != pattern[index] for index in range(col_count))
                remaining = search(row_index + 1, updated)
                best = min(best, cost + remaining)
            return best

        answer = min(answer, search(0, (0,) * col_count))
    return -1 if answer >= INF else answer


def oracle(text):
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    position = 0
    case_count = int(lines[position])
    position += 1
    answers = []
    for case_index in range(case_count):
        row_count, col_count = (int(value) for value in lines[position].split())
        position += 1
        matrix = []
        for _ in range(row_count):
            digits = "".join(character for character in lines[position] if character in "01")
            position += 1
            matrix.append([int(bit) for bit in digits[:col_count]])
        answers.append(f"Case {case_index + 1}: {oracle_case(matrix)}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
2 3
111
111
3 3
011
011
011
2 3
001
000
"""
SAMPLE_OUT = """Case 1: 0
Case 2: 3
Case 3: 1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1\n0\n") == "Case 1: 0\n"
assert oracle("1\n2 2\n10\n01\n") == "Case 1: 0\n"
assert oracle("1\n2 2\n11\n00\n") == "Case 1: 2\n"
assert oracle("1\n2 3\n001\n000\n") == "Case 1: 1\n"
assert oracle("1\n3 3\n111\n111\n111\n") == "Case 1: 0\n"
assert gcd(4, 6) == 2


def write(name, matrices):
    parts = [str(len(matrices))]
    for matrix in matrices:
        parts.append(f"{len(matrix)} {len(matrix[0])}")
        for row in matrix:
            parts.append("".join(str(value) for value in row))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = [
        [[0]],
        [[1, 1, 1], [1, 1, 1]],
        [[0, 0], [1, 1]],
        [[1, 0], [0, 1]],
        [[1, 0, 1], [0, 1, 0], [1, 0, 1]],
    ]
    write("2_edges", edges)
    rng = random.Random(20261126)
    wide = [[[rng.randint(0, 1) for _ in range(4)] for _ in range(4)] for _ in range(4)]
    write("3_wide", wide)
    random_matrices = []
    for _ in range(8):
        rows = rng.randint(2, 4)
        columns = rng.randint(2, 4)
        random_matrices.append(
            [[rng.randint(0, 1) for _ in range(columns)] for _ in range(rows)])
    write("4_random", random_matrices)
    io_matrices = [
        [[rng.randint(0, 1) for _ in range(3)] for _ in range(3)] for _ in range(25)
    ]
    write("5_io", io_matrices)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    [[1, 1, 1], [1, 1, 1]],
    [[0, 1, 1], [0, 1, 1], [0, 1, 1]],
    [[0, 0, 1], [0, 0, 0]],
])
build()
