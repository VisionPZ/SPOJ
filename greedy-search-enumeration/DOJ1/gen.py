#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def tileable(free_rows, rows):
    run = 0
    for row in range(rows):
        if row in free_rows:
            run += 1
        else:
            if run % 2:
                return False
            run = 0
    return run % 2 == 0


def build_transfer(rows):
    size = 1 << rows
    matrix = [[0] * size for _ in range(size)]
    for incoming in range(size):
        for outgoing in range(size):
            if incoming & outgoing:
                continue
            free = set(row for row in range(rows)
                       if not (incoming >> row) & 1 and not (outgoing >> row) & 1)
            if tileable(free, rows):
                matrix[incoming][outgoing] = 1
    return matrix


def build_hole_transfer(rows, hole_row):
    size = 1 << rows
    matrix = [[0] * size for _ in range(size)]
    for incoming in range(size):
        for outgoing in range(size):
            if incoming & outgoing:
                continue
            if (incoming >> hole_row) & 1 or (outgoing >> hole_row) & 1:
                continue
            free = set(row for row in range(rows)
                       if row != hole_row and not (incoming >> row) & 1
                       and not (outgoing >> row) & 1)
            if tileable(free, rows):
                matrix[incoming][outgoing] = 1
    return matrix


def multiply(left, right, modulus):
    size = len(left)
    return [[sum(left[row][inner] * right[inner][col] for inner in range(size)) % modulus
             for col in range(size)] for row in range(size)]


def power(matrix, exponent, modulus):
    size = len(matrix)
    result = [[int(row == col) for col in range(size)] for row in range(size)]
    base = [row[:] for row in matrix]
    while exponent:
        if exponent & 1:
            result = multiply(result, base, modulus)
        base = multiply(base, base, modulus)
        exponent >>= 1
    return result


def oracle_case(rows, columns, hole_row, hole_column, modulus):
    transfer = build_transfer(rows)
    hole = build_hole_transfer(rows, hole_row - 1)
    size = 1 << rows
    left_matrix = power(transfer, hole_column - 1, modulus)
    vector = [int(index == 0) for index in range(size)]
    vector = [sum(vector[row] * left_matrix[row][col] for row in range(size)) % modulus
              for col in range(size)]
    vector = [sum(vector[row] * hole[row][col] for row in range(size)) % modulus
              for col in range(size)]
    right_matrix = power(transfer, columns - hole_column, modulus)
    other = [int(index == 0) for index in range(size)]
    other = [sum(right_matrix[row][col] * other[col] for col in range(size)) % modulus
             for row in range(size)]
    return sum(vector[row] * other[row] for row in range(size)) % modulus


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    position = 1
    for _ in range(case_count):
        values = [int(token) for token in tokens[position:position + 5]]
        position += 5
        answers.append(str(oracle_case(*values)))
    return "\n".join(answers) + "\n"


def trivial_oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    position = 1
    for _ in range(case_count):
        rows, columns, hole_row, hole_column, modulus = (
            int(token) for token in tokens[position:position + 5])
        position += 5
        if rows * columns % 2 == 0 or (hole_row + hole_column) % 2:
            answers.append("0")
        else:
            answers.append(str(1 % modulus))
    return "\n".join(answers) + "\n"


SAMPLE = """3
1 3 1 3 100
2 3 2 2 100
3 7 1 3 100
"""
SAMPLE_OUT = """1
0
56
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(1, 3, 1, 1, 100) == 1
assert oracle_case(2, 3, 2, 2, 100) == 0
assert oracle_case(3, 3, 2, 2, 100) == 2
assert oracle_case(4, 6, 1, 1, 100) == 0
assert oracle_case(3, 7, 1, 3, MOD) == 56


def write(name, cases, generator=oracle):
    lines = [str(len(cases))] + [" ".join(str(value) for value in case) for case in cases]
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(generator(text))


def build():
    write("2_edges", [
        (1, 1, 1, 1, 1),
        (1, 3, 1, 2, 100),
        (2, 3, 2, 2, 100),
        (4, 5, 4, 5, 7),
        (3, 3, 2, 2, 100),
    ])
    write("3_wide", [
        (3, 1000000000, 1, 999999999, 1000000007),
        (4, 1000000000, 3, 1, 999999937),
        (1, 999999999, 1, 999999999, 100),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(200):
        rows = rng.randint(1, 4)
        columns = rng.randint(1, 1000000000)
        cases.append((rows, columns, rng.randint(1, rows),
                      rng.randint(1, columns), rng.randint(1, 1000000000)))
    write("4_random", cases)
    cases = []
    for _ in range(30000):
        rows = 2 if rng.random() < 0.6 else 1
        columns = rng.randint(1, 1000000000)
        if columns % 2 == 0:
            columns += 1
        cases.append((rows, columns, rng.randint(1, rows),
                      2 * rng.randint(1, columns // 2) - 1 if rows == 1
                      else rng.randint(1, rows), rng.randint(1, 1000000000)))
    write("5_io", cases, trivial_oracle)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
