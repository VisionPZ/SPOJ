#!/usr/bin/env python3
import random
import sys
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.setrecursionlimit(100000)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        rows = tokens[cursor]
        columns = tokens[cursor + 1]
        cursor += 2
        grid = []
        for _ in range(rows):
            grid.append(tokens[cursor:cursor + columns])
            cursor += columns

        @lru_cache(maxsize=None)
        def best_from(row, column):
            here = grid[row][column]
            if row == rows - 1:
                return here
            options = [best_from(row + 1, column)]
            if column > 0:
                options.append(best_from(row + 1, column - 1))
            if column + 1 < columns:
                options.append(best_from(row + 1, column + 1))
            return here + max(options)

        answers.append(str(max(best_from(0, column) for column in range(columns))))
        best_from.cache_clear()
    return "\n".join(answers) + "\n"


SAMPLE_IN = """1
6 5
3 1 7 4 2
2 1 3 1 1
1 2 2 1 8
2 2 1 5 3
2 1 4 4 4
5 2 7 5 1
"""
SAMPLE_OUT = """32
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n1 1\n7\n") == "7\n"
assert oracle("1\n3 1\n1\n2\n3\n") == "6\n"
assert oracle("1\n1 4\n1 2 3 4\n") == "4\n"
assert oracle("1\n2 2\n1 100\n100 1\n") == "200\n"


def write(name, cases):
    lines = [str(len(cases))]
    for rows in cases:
        lines.append(f"{len(rows)} {len(rows[0])}")
        for row in rows:
            lines.append(" ".join(str(value) for value in row))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [[[7]], [[1], [2], [3]], [[1, 100, 2, 99]], [[0, 0], [0, 0]]])
    rng = random.Random(20261126)
    write("3_wide", [[[rng.randint(0, 100) for _ in range(100)] for _ in range(100)]])
    random_cases = []
    for _ in range(30):
        case_rows = rng.randint(1, 12)
        case_columns = rng.randint(1, 12)
        random_cases.append([[rng.randint(0, 100) for _ in range(case_columns)]
                             for _ in range(case_rows)])
    write("4_random", random_cases)
    write("5_io", [[[rng.randint(0, 100) for _ in range(100)] for _ in range(100)]
                   for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
