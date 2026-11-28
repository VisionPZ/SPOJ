#!/usr/bin/env python3
from fractions import Fraction
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def spanning_tree_count_fraction(city_count, edges):
    if city_count == 1:
        return 1
    size = city_count - 1
    matrix = [[0] * size for _ in range(size)]
    for first, second in edges:
        if first < size:
            matrix[first][first] += 1
        if second < size:
            matrix[second][second] += 1
        if first < size and second < size:
            matrix[first][second] -= 1
            matrix[second][first] -= 1
    work = [[Fraction(value) for value in row] for row in matrix]
    result = Fraction(1)
    for column in range(size):
        pivot = next((row for row in range(column, size) if work[row][column] != 0), None)
        if pivot is None:
            return 0
        if pivot != column:
            work[column], work[pivot] = work[pivot], work[column]
            result = -result
        pivot_value = work[column][column]
        result *= pivot_value
        for row in range(column + 1, size):
            factor = work[row][column] / pivot_value
            for col in range(column, size):
                work[row][col] -= factor * work[column][col]
    return int(result)


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        cities = int(tokens[cursor]); cursor += 1
        edges_count = int(tokens[cursor]); cursor += 1
        edges = []
        for _ in range(edges_count):
            first = int(tokens[cursor]); cursor += 1
            second = int(tokens[cursor]); cursor += 1
            edges.append((first - 1, second - 1))
        answers.append(str(spanning_tree_count_fraction(cities, edges)))
    return "\n".join(answers) + "\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{cities} {len(edges)}\n" +
        "".join(f"{first} {second}\n" for first, second in edges) + "\n"
        for cities, edges in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = [(4, [(3, 4), (4, 2), (2, 3), (1, 2), (1, 3)]),
          (2, [(2, 1)]), (1, []), (3, [(1, 2), (2, 3), (3, 1)])]
assert oracle("4\n" + "".join(
    f"{c} {len(e)}\n" + "".join(f"{a} {b}\n" for a, b in e) + "\n"
    for c, e in SAMPLE)) == "8\n1\n1\n3\n"


def build():
    write("2_edges", [
        (1, []), (2, []), (2, [(1, 2)]), (3, [(1, 2)]),
        (3, [(1, 2), (2, 3)]), (3, [(1, 2), (1, 3), (2, 3)]),
        (4, [(1, 2), (3, 4)]),
    ])

    wide = [(12, list(itertools.combinations(range(1, 13), 2))),
            (12, [(index, index + 1) for index in range(1, 12)]),
            (11, [(1, index) for index in range(2, 12)]),
            (10, [(index, index + 1) for index in range(1, 10)] +
                 [(1, 10)])]
    write("3_wide", wide)

    random.seed(3141)
    random_cases = []
    for _ in range(120):
        cities = random.randint(1, 12)
        possible = list(itertools.combinations(range(1, cities + 1), 2))
        random.shuffle(possible)
        edges = possible[:random.randint(0, len(possible))]
        random_cases.append((cities, edges))
    write("4_random", random_cases)

    io_cases = []
    for _ in range(1000):
        cities = random.randint(1, 8)
        possible = list(itertools.combinations(range(1, cities + 1), 2))
        random.shuffle(possible)
        edges = possible[:random.randint(0, len(possible))]
        io_cases.append((cities, edges))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
