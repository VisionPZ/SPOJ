#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 15


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cities = tokens[0]
    roads = tokens[1]
    cursor = 2
    matrix = [[INF] * cities for _ in range(cities)]
    for index in range(cities):
        matrix[index][index] = 0
    for _ in range(roads):
        first, second, length = tokens[cursor:cursor + 3]
        cursor += 3
        matrix[first][second] = min(matrix[first][second], length)
    for middle in range(cities):
        for first in range(cities):
            if matrix[first][middle] >= INF:
                continue
            for second in range(cities):
                if matrix[middle][second] >= INF:
                    continue
                candidate = matrix[first][middle] + matrix[middle][second]
                if candidate < matrix[first][second]:
                    matrix[first][second] = candidate
    best = matrix[0][cities - 1]
    queries = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(queries):
        road_from = tokens[cursor]
        road_to = tokens[cursor + 1]
        cost = tokens[cursor + 2]
        cursor += 3
        candidate = matrix[0][road_from] + cost + matrix[road_to][cities - 1]
        if candidate < best:
            answers.append(f"Boleh juga: {candidate} km")
        else:
            answers.append("Tidaakkk...")
    return "\n".join(answers) + "\n"


SAMPLE = """4 3
2 3 5
0 1 1
1 2 2
2
0 2 1
0 2 4
"""
SAMPLE_OUT = """Boleh juga: 6 km
Tidaakkk...
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1\n0 1 5\n1\n0 1 9\n") == "Tidaakkk...\n"
assert oracle("2 1\n0 1 5\n1\n0 1 1\n") == "Boleh juga: 1 km\n"
assert oracle("4 3\n0 1 2\n1 3 2\n0 2 1\n1\n1 3 1\n") == "Boleh juga: 3 km\n"


def write(name, cities, roads, queries):
    lines = [f"{cities} {len(roads)}"]
    lines.extend(f"{first} {second} {length}" for first, second, length in roads)
    lines.append(str(len(queries)))
    lines.extend(f"{first} {second} {cost}" for first, second, cost in queries)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2, [(0, 1, 1)], [(0, 1, 1), (1, 0, 5)])
    write("3_wide", 8, [(index, index + 1, 1000000) for index in range(7)],
          [(0, 7, 1), (6, 7, 1000000), (0, 5, 999999)])
    rng = random.Random(20261126)
    roads = []
    for index in range(30):
        first = rng.randint(0, 7)
        second = rng.randint(0, 7)
        roads.append((first, second, rng.randint(1, 50)))
    queries = [(rng.randint(0, 7), rng.randint(0, 7), rng.randint(1, 60))
               for _ in range(40)]
    write("4_random", 8, roads, queries)
    queries = [(rng.randint(0, 9), rng.randint(0, 9), rng.randint(1, 20))
               for _ in range(300)]
    write("5_io", 10, [(index, index + 1, 5) for index in range(9)], queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 4, [(2, 3, 5), (0, 1, 1), (1, 2, 2)], [(0, 2, 1), (0, 2, 4)])
build()
