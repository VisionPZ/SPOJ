#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    negative = -10 ** 9
    for _ in range(case_count):
        rows = int(tokens[cursor])
        columns = int(tokens[cursor + 1])
        operations = int(tokens[cursor + 2])
        cursor += 3
        grid = tokens[cursor:cursor + rows]
        cursor += rows
        on_counts = [line.count('*') for line in grid]
        table = [[negative] * (operations + 1) for _ in range(rows + 1)]
        table[0][0] = 0
        for row_index in range(1, rows + 1):
            for used in range(operations + 1):
                best = negative
                for toggles in range(used + 1):
                    previous = table[row_index - 1][used - toggles]
                    if previous == negative:
                        continue
                    value = columns - on_counts[row_index - 1] if toggles % 2 else on_counts[row_index - 1]
                    if previous + value > best:
                        best = previous + value
                table[row_index][used] = best
        answers.append(str(table[rows][operations]))
    return "\n".join(answers) + "\n"


SAMPLE = """2
2 2 1
..
**
2 2 2
..
**
"""
SAMPLE_OUT = """4
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 1\n.\n") == "1\n"
assert oracle("1\n1 1 2\n.\n") == "0\n"
assert oracle("1\n2 3 3\n***\n...\n") == "6\n"


def write(name, cases):
    pieces = [str(len(cases))]
    for rows, columns, operations, grid in cases:
        pieces.append(f"{rows} {columns} {operations}")
        pieces.extend(grid)
    text = "\n".join(pieces) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(rng, rows, columns, operations):
    grid = ["".join(rng.choice(".*") for _ in range(columns)) for _ in range(rows)]
    return rows, columns, operations, grid


def build():
    write("2_edges", [
        (1, 1, 1, ["."]), (1, 1, 2, ["*"]), (2, 1, 3, [".", "*"]),
        (3, 4, 2, ["*...", "....", "****"]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [make_case(rng, 50, 50, 100)])
    random_cases = [make_case(rng, rng.randint(1, 8), rng.randint(1, 8), rng.randint(1, 12))
                    for _ in range(20)]
    write("4_random", random_cases)
    io_cases = [make_case(rng, 5, 5, 10) for _ in range(100)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
