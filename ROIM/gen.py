#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(node_count, edges):
    paths = []

    def walk(node, used_edges, charter_count, total_cost):
        if node == node_count - 1:
            paths.append((frozenset(used_edges), charter_count, total_cost))
            return
        if len(used_edges) > node_count:
            return
        for edge_index, (start, end, is_charter, fare) in enumerate(edges):
            if start == node and edge_index not in used_edges:
                walk(end, used_edges + [edge_index],
                     charter_count + is_charter, total_cost + fare)

    walk(0, [], 0, 0)
    best = None
    for first_index, first_path in enumerate(paths):
        for second_path in paths[first_index:]:
            if first_path[0].isdisjoint(second_path[0]):
                candidate = (first_path[1] + second_path[1],
                             first_path[2] + second_path[2])
                if best is None or candidate < best:
                    best = candidate
    return best


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while cursor + 2 < len(tokens):
        node_count = int(tokens[cursor])
        regular_count = int(tokens[cursor + 1])
        charter_count = int(tokens[cursor + 2])
        cursor += 3
        if node_count == 0 and regular_count == 0 and charter_count == 0:
            break
        edges = []
        for _ in range(regular_count):
            start = int(tokens[cursor])
            end = int(tokens[cursor + 1])
            fare = int(tokens[cursor + 2])
            cursor += 3
            edges.append((start, end, 0, fare))
        for _ in range(charter_count):
            start = int(tokens[cursor])
            end = int(tokens[cursor + 1])
            fare = int(tokens[cursor + 2])
            cursor += 3
            edges.append((start, end, 1, fare))
        best = oracle_case(node_count, edges)
        answers.append("Boa viagem, Roim" if best is None else f"{best[0]} {best[1]}")
    return "\n".join(answers) + "\n"


SAMPLE = """4 5 0
0 1 1
1 3 5
0 2 5
1 2 1
2 3 1

4 4 1
0 1 2
1 3 2
0 2 2
1 2 1
2 3 2

2 1 0
0 1 1
0 0 0
"""
SAMPLE_OUT = """0 12
1 8
Boa viagem, Roim
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1 0\n0 1 5\n0 0 0\n") == "Boa viagem, Roim\n"
assert oracle("3 2 0\n0 2 1\n0 1 1\n0 0 0\n") == "Boa viagem, Roim\n"
assert oracle("3 4 0\n0 1 2\n1 2 3\n0 2 7\n1 0 1\n0 0 0\n") == "0 12\n"
assert oracle("3 2 1\n0 1 1\n1 2 1\n0 2 2\n0 0 0\n") == "1 4\n"


def write(name, cases):
    chunks = []
    for node_count, edges in cases:
        regular = [edge for edge in edges if edge[2] == 0]
        charter = [edge for edge in edges if edge[2] == 1]
        chunks.append(f"{node_count} {len(regular)} {len(charter)}")
        for start, end, _, fare in regular + charter:
            chunks.append(f"{start} {end} {fare}")
    chunks.append("0 0 0")
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng):
    node_count = rng.randint(3, 6)
    candidates = [(start, end) for start in range(node_count)
                  for end in range(node_count) if start != end]
    rng.shuffle(candidates)
    chosen = candidates[:rng.randint(2, 10)]
    edges = []
    for start, end in chosen:
        is_charter = 1 if rng.random() < 0.25 else 0
        edges.append((start, end, is_charter, rng.randint(1, 10)))
    return (node_count, edges)


def build():
    write("2_edges", [
        (2, [(0, 1, 0, 5)]),
        (3, [(0, 1, 0, 1), (1, 2, 0, 1)]),
        (3, [(0, 2, 1, 4), (0, 1, 0, 2), (1, 2, 0, 3)]),
        (4, [(0, 1, 0, 1), (1, 3, 0, 1), (0, 2, 0, 1), (2, 3, 0, 1),
             (1, 2, 0, 1), (2, 1, 0, 1)]),
    ])
    wide_edges = []
    for start in range(5):
        for end in range(start + 1, 5):
            wide_edges.append((start, end, 0, 1 + (start + end) % 7))
            wide_edges.append((end, start, 1, 1 + (start * end) % 5))
    write("3_wide", [(5, wide_edges), (5, wide_edges)])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng) for _ in range(25)])
    write("5_io", [random_case(rng) for _ in range(80)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (4, [(0, 1, 0, 1), (1, 3, 0, 5), (0, 2, 0, 5), (1, 2, 0, 1), (2, 3, 0, 1)]),
    (4, [(0, 1, 0, 2), (1, 3, 0, 2), (0, 2, 0, 2), (1, 2, 0, 1), (2, 3, 1, 2)]),
    (2, [(0, 1, 0, 1)]),
])
build()
