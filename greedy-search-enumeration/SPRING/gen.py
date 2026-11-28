#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor + 3 <= len(tokens):
        bar_count = tokens[cursor]
        spring_count = tokens[cursor + 1]
        target_distance = tokens[cursor + 2]
        cursor += 3
        edges = []
        for _ in range(spring_count):
            first = tokens[cursor]
            second = tokens[cursor + 1]
            constant = tokens[cursor + 2]
            cursor += 3
            edges.append((first, second, constant))
        graph = [[] for _ in range(bar_count)]
        for first, second, constant in edges:
            graph[first].append((second, 1.0 / constant))
            graph[second].append((first, 1.0 / constant))
        best_sum = math.inf
        stack = [(0, frozenset([0]), 0.0)]
        while stack:
            node, visited, path_sum = stack.pop()
            if node == bar_count - 1:
                if path_sum < best_sum:
                    best_sum = path_sum
                continue
            if path_sum >= best_sum:
                continue
            for neighbour, edge_weight in graph[node]:
                if neighbour not in visited:
                    stack.append((neighbour, visited | {neighbour},
                                  path_sum + edge_weight))
        force = target_distance / best_sum
        rounded = math.floor(force * 100.0 + 0.5) / 100.0
        answers.append(f"{rounded:.2f}")
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """3 2 5
1 0 1
1 2 1
3 3 5
1 0 1
1 2 1
0 2 2
4 5 100
0 2 1
0 2 1
2 1 1
2 1 1
1 3 2
"""
SAMPLE_OUT = """2.50
10.00
40.00
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1 10\n0 1 2\n") == "20.00\n"
assert oracle("2 3 7\n0 1 1\n0 1 2\n0 1 7\n") == "49.00\n"
assert oracle("3 2 1\n0 1 3\n1 2 3\n") == "1.50\n"
assert oracle("3 2 1\n0 1 100000\n1 2 100000\n") == "50000.00\n"


def case(bar_count, target_distance, springs):
    lines = [f"{bar_count} {len(springs)} {target_distance}"]
    for first, second, constant in springs:
        lines.append(f"{first} {second} {constant}")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = "".join(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [case(2, 7, [(0, 1, 1), (0, 1, 2), (0, 1, 7)])])
    write("3_wide", [case(5, 100, [
        (0, 1, 10), (1, 2, 20), (2, 3, 10), (3, 4, 1),
        (0, 2, 100), (1, 4, 50), (2, 4, 30), (0, 4, 1000),
    ])])
    rng = random.Random(20261126)
    random_springs = [(city, city + 1, rng.randint(1, 100000)) for city in range(5)]
    random_springs += [
        (rng.randrange(6), rng.randrange(6), rng.randint(1, 100000))
        for _ in range(10)
    ]
    write("4_random", [case(6, rng.randint(1, 100000), random_springs)])
    many_cases = []
    for _ in range(200):
        many_cases.append(case(2, rng.randint(1, 100000), [
            (0, 1, rng.randint(1, 100000))
        ]))
    write("5_io", many_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
