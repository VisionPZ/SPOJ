#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(vertex_count, edges, queries):
    capacity = [[0] * vertex_count for _ in range(vertex_count)]
    for first, second, weight in edges:
        capacity[first - 1][second - 1] += weight
        capacity[second - 1][first - 1] += weight
    pair_values = []
    for source in range(vertex_count):
        for sink in range(source + 1, vertex_count):
            best = None
            for mask in range(1 << vertex_count):
                if not (mask >> source) & 1 or (mask >> sink) & 1:
                    continue
                cut = 0
                for first in range(vertex_count):
                    if (mask >> first) & 1:
                        for second in range(vertex_count):
                            if not (mask >> second) & 1:
                                cut += capacity[first][second]
                if best is None or cut < best:
                    best = cut
            pair_values.append(best)
    return [sum(1 for value in pair_values if value <= limit) for limit in queries]


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for case_index in range(case_count):
        vertex_count = tokens[position]
        edge_count = tokens[position + 1]
        position += 2
        edges = []
        for _ in range(edge_count):
            edges.append((tokens[position], tokens[position + 1], tokens[position + 2]))
            position += 3
        query_count = tokens[position]
        position += 1
        queries = tokens[position:position + query_count]
        position += query_count
        case_answers = [str(value) for value in oracle_case(vertex_count, edges, queries)]
        if answers:
            answers.append("")
        answers.extend(case_answers)
    return "\n".join(answers) + "\n"


SAMPLE = """1
5 0
1
0
"""
SAMPLE_OUT = """10
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n1 2 5\n3\n0\n4\n5\n") == "0\n0\n1\n"
assert oracle("1\n3 2\n1 2 3\n2 3 4\n3\n0\n3\n7\n") == "0\n2\n3\n"
assert oracle("1\n4 1\n1 2 6\n2\n5\n6\n") == "5\n6\n"


def write(name, cases):
    parts = [str(len(cases))]
    for vertex_count, edges, queries in cases:
        parts.append(f"{vertex_count} {len(edges)}")
        for first, second, weight in edges:
            parts.append(f"{first} {second} {weight}")
        parts.append(str(len(queries)))
        parts.extend(str(value) for value in queries)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(vertex_count, edge_probability, query_count, rng):
    edges = []
    for first in range(1, vertex_count + 1):
        for second in range(first + 1, vertex_count + 1):
            if rng.random() < edge_probability:
                for _ in range(rng.randint(1, 2)):
                    edges.append((first, second, rng.randint(1, 1000000)))
    queries = [rng.randint(0, 2000000) for _ in range(query_count)]
    return vertex_count, edges, queries


def build():
    write("2_edges", [
        (2, [], [0, 1]),
        (3, [(1, 2, 5)], [0, 4, 5]),
        (4, [(1, 2, 3), (1, 2, 4)], [0, 6, 7]),
        (4, [(1, 2, 3), (2, 3, 4), (3, 4, 5)], [0, 3, 6, 12]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_case(9, 0.5, 8, rng), random_case(10, 0.1, 8, rng)])
    write("4_random", [random_case(rng.randint(2, 9), rng.choice([0.0, 0.2, 0.5, 0.9]),
                                   rng.randint(1, 8), rng) for _ in range(10)])
    write("5_io", [random_case(9, 0.4, 30, rng) for _ in range(3)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
