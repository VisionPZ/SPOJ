#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(weights, edges, members):
    best = 0
    member_set = set(members)
    for size in range(len(members) + 1):
        for subset in itertools.combinations(members, size):
            chosen = set(subset)
            if any(u in chosen and v in chosen for u, v in edges
                   if u in member_set and v in member_set):
                continue
            total = sum(weights[vertex] for vertex in subset)
            if total > best:
                best = total
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        vertex_count = tokens[position]
        edge_count = tokens[position + 1]
        position += 2
        weights = tokens[position:position + vertex_count]
        position += vertex_count
        edges = []
        for _ in range(edge_count):
            edges.append((tokens[position], tokens[position + 1]))
            position += 2
        query_count = tokens[position]
        position += 1
        case_answers = []
        for _ in range(query_count):
            member_count = tokens[position]
            members = tokens[position + 1:position + 1 + member_count]
            position += 1 + member_count
            case_answers.append(str(oracle_case(weights, edges, members)))
        if answers:
            answers.append("")
        answers.extend(case_answers)
    return "\n".join(answers) + "\n"


SAMPLE = """2
5 1
1 2 3 4 5
0 1
3
3 0 1 2
3 1 2 3
2 0 1
3 3
1 2 3
0 1
0 2
1 2
1
3 0 1 2
"""
SAMPLE_OUT = """5
9
2

3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n4 7\n0 1\n1\n2 0 1\n") == "7\n"
assert oracle("1\n3 0\n1 2 3\n1\n3 0 1 2\n") == "6\n"
assert oracle("1\n4 2\n5 6 7 8\n0 1\n2 3\n2\n4 0 1 2 3\n2 1 3\n") == "14\n14\n"


def write(name, cases):
    parts = [str(len(cases))]
    for weights, edges, queries in cases:
        parts.append(f"{len(weights)} {len(edges)}")
        parts.append(" ".join(str(value) for value in weights))
        for first, second in edges:
            parts.append(f"{first} {second}")
        parts.append(str(len(queries)))
        for members in queries:
            parts.append(f"{len(members)} " + " ".join(str(value) for value in members))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(vertex_count, edge_probability, query_count, rng):
    weights = [rng.randint(1, 1000) for _ in range(vertex_count)]
    edges = [(first, second) for first in range(vertex_count)
             for second in range(first + 1, vertex_count)
             if rng.random() < edge_probability]
    queries = []
    for _ in range(query_count):
        size = rng.randint(0, vertex_count)
        queries.append(rng.sample(range(vertex_count), size))
    return weights, edges, queries


def build():
    write("2_edges", [
        ([1, 2, 3, 4, 5], [(0, 1)], [[0, 1, 2], [1, 2, 3], [0, 1], [4]]),
        ([3, 3, 3], [], [[0, 1, 2], [1, 2]]),
        ([5, 6, 7, 8], [(0, 1), (2, 3)], [[0, 1, 2, 3], [0, 2], [1, 3]]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_case(12, 0.0, 6, rng),
                     random_case(12, 0.5, 6, rng),
                     random_case(14, 0.9, 6, rng)])
    write("4_random", [random_case(rng.randint(3, 12), rng.choice([0.0, 0.2, 0.5, 0.8]),
                                   rng.randint(1, 10), rng) for _ in range(12)])
    write("5_io", [random_case(12, 0.3, 60, rng) for _ in range(3)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
