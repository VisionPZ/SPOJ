#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent


def solve_case(tokens, position):
    count = int(tokens[position])
    position += 1
    paths = int(tokens[position])
    position += 1
    weights = [[0.0] * count for _ in range(count)]
    for _ in range(paths):
        first = int(tokens[position])
        second = int(tokens[position + 1])
        joy = float(tokens[position + 2])
        snow = float(tokens[position + 3])
        position += 4
        value = joy / snow
        weights[first][second] = value
        weights[second][first] = value
    matrix = np.zeros((count, count), dtype=float)
    for index in range(count):
        total = sum(weights[index])
        if total > 0:
            for neighbor in range(count):
                matrix[index][neighbor] = weights[index][neighbor] / total
    queries = int(tokens[position])
    position += 1
    lines = []
    for _ in range(queries):
        elapsed = int(tokens[position])
        starting = int(tokens[position + 1])
        position += 2
        starts = [int(tokens[position + index]) for index in range(starting)]
        position += starting
        vectors = np.zeros((starting, count), dtype=float)
        for row, start in enumerate(starts):
            if 0 <= start < count:
                vectors[row][start] = 1.0
        for _ in range(elapsed):
            vectors = vectors @ matrix
        answers = []
        for row in range(starting):
            best = -1
            best_value = 0.0
            for node in range(count):
                if vectors[row][node] > best_value + 1e-12:
                    best_value = vectors[row][node]
                    best = node
            answers.append(str(best))
        lines.append(" ".join(answers))
    return lines


def exact_case(count, edges, elapsed, starts):
    weights = [[Fraction(0) for _ in range(count)] for _ in range(count)]
    for first, second, joy, snow in edges:
        value = Fraction(joy, snow)
        weights[first][second] = value
        weights[second][first] = value
    matrix = [[Fraction(0) for _ in range(count)] for _ in range(count)]
    for index in range(count):
        total = sum(weights[index], Fraction(0))
        if total > 0:
            for neighbor in range(count):
                matrix[index][neighbor] = weights[index][neighbor] / total
    answers = []
    for start in starts:
        vector = [Fraction(0) for _ in range(count)]
        if 0 <= start < count:
            vector[start] = Fraction(1)
        for _ in range(elapsed):
            vector = [sum((vector[row] * matrix[row][node] for row in range(count)), Fraction(0))
                      for node in range(count)]
        best = -1
        best_value = Fraction(0)
        for node in range(count):
            if vector[node] > best_value:
                best_value = vector[node]
                best = node
        answers.append(str(best))
    return " ".join(answers)


def oracle(text):
    tokens = text.split()
    position = 0
    cases = int(tokens[position])
    position += 1
    blocks = []
    for case_index in range(cases):
        lines = solve_case(tokens, position)
        position = advance(tokens, position)
        blocks.append("Scenario #" + str(case_index + 1) + ":\n\n" + "\n".join(lines) + "\n\n")
    return "".join(blocks)


def advance(tokens, position):
    count = int(tokens[position])
    position += 1
    paths = int(tokens[position])
    position += 1
    position += 4 * paths
    queries = int(tokens[position])
    position += 1
    for _ in range(queries):
        starting = int(tokens[position + 1])
        position += 2 + starting
    return position


SAMPLE = """2
3 3
0 1 10 2
0 2 1 8
1 2 100 1
2
1 1 0
2 1 0
4 5
0 1 10 2
1 3 2 3
0 2 4 8
2 1 1 10
2 3 1 1
2
2 1 2
10 2 0 3
"""
SAMPLE_OUT = """Scenario #1:

1
2

Scenario #2:

1
0 0

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert exact_case(2, [(0, 1, 1, 1)], 1, [0, 1]) == "1 0"
assert exact_case(2, [(0, 1, 1, 1)], 2, [0, 1]) == "0 1"
assert exact_case(3, [(0, 1, 10, 2), (0, 2, 1, 8), (1, 2, 100, 1)], 1, [0]) == "1"
assert exact_case(3, [(0, 1, 10, 2), (0, 2, 1, 8), (1, 2, 100, 1)], 2, [0]) == "2"
assert exact_case(3, [], 1, [0, 1]) == "-1 -1"


def build_text(cases):
    lines = [str(len(cases))]
    for count, paths, edges, queries in cases:
        lines.append(f"{count} {paths}")
        for first, second, joy, snow in edges:
            lines.append(f"{first} {second} {joy} {snow}")
        lines.append(str(len(queries)))
        for elapsed, starts in queries:
            lines.append(f"{elapsed} {len(starts)}")
            lines.extend(str(start) for start in starts)
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = build_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def sample_cases():
    return [
        (3, 3, [(0, 1, 10, 2), (0, 2, 1, 8), (1, 2, 100, 1)], [(1, [0]), (2, [0])]),
        (4, 5, [(0, 1, 10, 2), (1, 3, 2, 3), (0, 2, 4, 8), (2, 1, 1, 10), (2, 3, 1, 1)],
         [(2, [2]), (10, [0, 3])]),
    ]


def build():
    write("2_edges", [(3, 0, [], [(1, [0, 1, 2])]),
                      (2, 1, [(0, 1, 1, 1)], [(1, [0, 1]), (2, [0, 1])]),
                      (4, 2, [(0, 1, 3, 4), (2, 3, 5, 6)], [(3, [0, 2, 3])])])
    rng = random.Random(20261126)
    wide = []
    for _ in range(5):
        count = 40
        paths = []
        for first in range(count):
            for second in range(first + 1, count):
                if rng.random() < 0.15:
                    paths.append((first, second, rng.randint(1, 100), rng.randint(1, 100)))
        queries = []
        for _ in range(4):
            starts = [rng.randrange(count) for _ in range(12)]
            queries.append((rng.randint(1, 50), starts))
        wide.append((count, len(paths), paths, queries))
    write("3_wide", wide)
    write("4_random", wide[:2])
    write("5_io", wide)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", sample_cases())
build()
