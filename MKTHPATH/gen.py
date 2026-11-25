#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def enumerate_paths(nodes, start, goal, edges):
    results = []

    def visit(node, path, visited, cost):
        if node == goal:
            results.append((cost, tuple(path)))
            return
        for neighbour in range(1, nodes + 1):
            length = edges[node][neighbour]
            if length == 0 or neighbour in visited:
                continue
            visited.add(neighbour)
            path.append(neighbour)
            visit(neighbour, path, visited, cost + length)
            path.pop()
            visited.remove(neighbour)

    visit(start, [start], {start}, 0)
    results.sort()
    return results


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while True:
        nodes = tokens[cursor]
        edges_count = tokens[cursor + 1]
        rank = tokens[cursor + 2]
        start = tokens[cursor + 3]
        goal = tokens[cursor + 4]
        cursor += 5
        if nodes == edges_count == rank == start == goal == 0:
            break
        edges = [[0] * (nodes + 1) for _ in range(nodes + 1)]
        for _ in range(edges_count):
            from_node = tokens[cursor]
            to_node = tokens[cursor + 1]
            length = tokens[cursor + 2]
            cursor += 3
            edges[from_node][to_node] = length
        paths = enumerate_paths(nodes, start, goal, edges)
        if len(paths) < rank:
            answers.append("None")
        else:
            answers.append("-".join(str(node) for node in paths[rank - 1][1]))
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """5 20 10 1 5
1 2 1
1 3 2
1 4 1
1 5 3
2 1 1
2 3 1
2 4 2
2 5 2
3 1 1
3 2 2
3 4 1
3 5 1
4 1 1
4 2 1
4 3 1
4 5 2
5 1 1
5 2 1
5 3 1
5 4 1
4 6 1 1 4
2 4 2
1 3 2
1 2 1
1 4 3
2 3 1
3 4 1
3 3 5 1 3
1 2 1
2 3 1
1 3 1
0 0 0 0 0
"""
SAMPLE_OUT = """1-2-4-3-5
1-2-3-4
None
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1 1 1 2\n1 2 7\n0 0 0 0 0\n") == "1-2\n"
assert oracle("2 1 2 1 2\n1 2 7\n0 0 0 0 0\n") == "None\n"
assert oracle("3 3 2 1 3\n1 2 1\n2 3 1\n1 3 5\n0 0 0 0 0\n") == "1-3\n"


def format_case(nodes, rank, edges):
    lines = [f"{nodes} {len(edges)} {rank} 1 {nodes}"]
    lines.extend(f"{first} {second} {length}" for first, second, length in edges)
    return lines


def write(name, cases):
    lines = []
    for nodes, rank, edges in cases:
        lines.extend(format_case(nodes, rank, edges))
    lines.append("0 0 0 0 0")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def dense_edges(rng, nodes, probability):
    edges = []
    for first in range(1, nodes + 1):
        for second in range(1, nodes + 1):
            if first != second and rng.random() < probability:
                edges.append((first, second, rng.randint(1, 10)))
    return edges


def build():
    write("2_edges", [
        (2, 1, [(1, 2, 5)]),
        (2, 2, [(1, 2, 5)]),
        (3, 3, [(1, 2, 1), (2, 3, 1), (1, 3, 5)]),
        (4, 5, [(1, 2, 1), (2, 3, 1), (3, 4, 1), (1, 4, 9)]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [(8, 30, dense_edges(rng, 8, 0.8))])
    random_cases = []
    for _ in range(10):
        nodes = rng.randint(4, 8)
        random_cases.append((nodes, rng.randint(1, 50), dense_edges(rng, nodes, 0.5)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(500):
        io_cases.append((5, rng.randint(1, 50), dense_edges(rng, 5, 0.7)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (5, 10, [(1, 2, 1), (1, 3, 2), (1, 4, 1), (1, 5, 3), (2, 1, 1), (2, 3, 1),
             (2, 4, 2), (2, 5, 2), (3, 1, 1), (3, 2, 2), (3, 4, 1), (3, 5, 1),
             (4, 1, 1), (4, 2, 1), (4, 3, 1), (4, 5, 2), (5, 1, 1), (5, 2, 1),
             (5, 3, 1), (5, 4, 1)]),
    (4, 1, [(2, 4, 2), (1, 3, 2), (1, 2, 1), (1, 4, 3), (2, 3, 1), (3, 4, 1)]),
    (3, 5, [(1, 2, 1), (2, 3, 1), (1, 3, 1)]),
])
build()
