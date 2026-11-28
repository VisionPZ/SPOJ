#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(node_count, path_budget, edges):
    infinity = 10 ** 15
    distance = [[infinity] * node_count for _ in range(node_count)]
    for index in range(node_count):
        distance[index][index] = 0
    for first, second, weight in edges:
        first -= 1
        second -= 1
        distance[first][second] = weight
        distance[second][first] = weight
    for middle in range(node_count):
        for first in range(node_count):
            for second in range(node_count):
                candidate = distance[first][middle] + distance[middle][second]
                if candidate < distance[first][second]:
                    distance[first][second] = candidate
    best = infinity
    for first in range(node_count):
        for second in range(node_count):
            if distance[first][second] > path_budget:
                continue
            on_path = [index for index in range(node_count)
                       if distance[first][index] + distance[index][second] == distance[first][second]]
            worst = 0
            for node in range(node_count):
                nearest = min(distance[node][index] for index in on_path)
                if nearest > worst:
                    worst = nearest
            if worst < best:
                best = worst
    return str(best) + "\n"


SAMPLE_IN = """2
5 2
1 2 5
2 3 2
2 4 4
2 5 3
8 6
1 3 2
2 3 2
3 4 6
4 5 3
4 6 4
4 7 2
7 8 3
"""
SAMPLE_OUT = """5
5
"""
assert oracle(5, 2, [(1, 2, 5), (2, 3, 2), (2, 4, 4), (2, 5, 3)]) == "5\n"
assert oracle(8, 6, [(1, 3, 2), (2, 3, 2), (3, 4, 6), (4, 5, 3),
                     (4, 6, 4), (4, 7, 2), (7, 8, 3)]) == "5\n"
assert oracle(1, 0, []) == "0\n"
assert oracle(2, 100, [(1, 2, 7)]) == "0\n"
assert oracle(5, 30, [(1, 2, 50), (2, 4, 40), (2, 3, 40), (2, 5, 30)]) == "50\n"


def write(name, cases):
    lines = [str(len(cases))]
    answers = []
    for node_count, path_budget, edges in cases:
        lines.append(f"{node_count} {path_budget}")
        for first, second, weight in edges:
            lines.append(f"{first} {second} {weight}")
        answers.append(oracle(node_count, path_budget, edges).rstrip("\n"))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


def random_tree(rng, node_count, max_weight):
    edges = []
    for node in range(2, node_count + 1):
        parent = rng.randint(1, node - 1)
        edges.append((parent, node, rng.randint(1, max_weight)))
    return edges


def build():
    write("2_edges", [
        (1, 0, []),
        (2, 0, [(1, 2, 7)]),
        (2, 7, [(1, 2, 7)]),
        (5, 30, [(1, 2, 50), (2, 4, 40), (2, 3, 40), (2, 5, 30)]),
        (4, 3, [(1, 2, 2), (2, 3, 2), (3, 4, 2)]),
    ])
    rng = random.Random(20261126)
    wide_edges = random_tree(rng, 40, 1000)
    write("3_wide", [(40, rng.randint(1000, 8000), wide_edges)])
    random_cases = []
    for _ in range(25):
        size = rng.randint(2, 12)
        random_cases.append((size, rng.randint(0, 4000), random_tree(rng, size, 1000)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(1000):
        size = rng.randint(1, 5)
        io_cases.append((size, rng.randint(0, 3000), random_tree(rng, size, 1000)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
