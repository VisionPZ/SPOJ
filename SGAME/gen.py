#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def can_draw(start, edges):
    def walk(current, used):
        if len(used) == len(edges):
            return current == start
        for edge_index, (first_vertex, second_vertex) in enumerate(edges):
            if edge_index in used:
                continue
            next_vertex = None
            if first_vertex == current:
                next_vertex = second_vertex
            elif second_vertex == current:
                next_vertex = first_vertex
            else:
                continue
            used.add(edge_index)
            if walk(next_vertex, used):
                return True
            used.remove(edge_index)
        return False

    return walk(start, set())


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_total = tokens[0]
    lines = []
    cursor = 1
    for _ in range(case_total):
        start = tokens[cursor]
        cursor += 1
        edges = []
        while True:
            first_vertex = tokens[cursor]
            second_vertex = tokens[cursor + 1]
            cursor += 2
            if first_vertex == -1 and second_vertex == -1:
                break
            edges.append((first_vertex, second_vertex))
        lines.append("YES" if can_draw(start, edges) else "NO")
    return "\n".join(lines) + "\n"


SAMPLE = """1
1
1 2
1 4
2 3
2 5
2 6
3 6
4 7
5 6
6 7
-1 -1
"""
SAMPLE_OUT = """YES
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n1 2\n-1 -1\n") == "NO\n"
assert oracle("1\n1\n1 2\n2 3\n3 1\n-1 -1\n") == "YES\n"
assert oracle("1\n1\n1 2\n2 3\n3 1\n4 5\n5 6\n6 4\n-1 -1\n") == "NO\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for start, edges in cases:
        text += str(start) + "\n"
        text += "".join(f"{first_vertex} {second_vertex}\n" for first_vertex, second_vertex in edges)
        text += "-1 -1\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, []),
        (1, [(1, 2)]),
        (1, [(1, 2), (2, 3), (3, 1)]),
        (2, [(1, 2), (2, 3), (3, 1)]),
        (1, [(1, 2), (2, 1)]),
    ])
    write("3_wide", [(300, [(300, 1), (300, 2), (1, 2), (2, 250), (250, 300)]),
                     (250, [(250, 251), (251, 252), (252, 250)])])
    rng = random.Random(20261126)
    cases = []
    for _ in range(20):
        vertex_count = rng.randint(2, 8)
        edge_count = rng.randint(0, 7)
        edges = []
        for _ in range(edge_count):
            first_vertex = rng.randint(1, vertex_count)
            second_vertex = rng.randint(1, vertex_count)
            if first_vertex != second_vertex and (second_vertex, first_vertex) not in edges and (first_vertex, second_vertex) not in edges:
                edges.append((first_vertex, second_vertex))
        cases.append((rng.randint(1, vertex_count), edges))
    write("4_random", cases)
    cases = []
    for index in range(100):
        first_vertex = 1 + index % 8
        second_vertex = 1 + (index + 1) % 8
        cases.append((first_vertex, [(first_vertex, second_vertex), (second_vertex, 9), (9, first_vertex)]))
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_cases = [(1, [(1, 2), (1, 4), (2, 3), (2, 5), (2, 6), (3, 6), (4, 7), (5, 6), (6, 7)])]
write("1_sample", sample_cases)
build()

rng = random.Random(19471208)
big_cases = []
for index in range(1000):
    hub = 1 + index % 300
    edges = []
    for offset in range(1, 12):
        edges.append((hub, 1 + (hub + offset) % 300))
    big_cases.append((hub, edges))
big_text = str(len(big_cases)) + "\n"
for start, edges in big_cases:
    big_text += str(start) + "\n"
    big_text += "".join(f"{first_vertex} {second_vertex}\n" for first_vertex, second_vertex in edges)
    big_text += "-1 -1\n"
Path("/tmp/SGAME_big.txt").write_text(big_text)
