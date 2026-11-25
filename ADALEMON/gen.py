#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def canonical(n, edges, removed):
    adjacency = [[] for _ in range(n)]
    for first, second in edges:
        if first == removed or second == removed:
            continue
        adjacency[first].append(second)
        adjacency[second].append(first)
    alive = [node for node in range(n) if node != removed]
    if not alive:
        return ()
    if len(alive) == 1:
        return ('single',)
    root = alive[0]
    parent = {root: -1}
    order = [root]
    for node in order:
        for neighbor in adjacency[node]:
            if neighbor not in parent:
                parent[neighbor] = node
                order.append(neighbor)
    sizes = {node: 1 for node in alive}
    for node in reversed(order):
        for neighbor in adjacency[node]:
            if parent.get(neighbor) == node:
                sizes[node] += sizes[neighbor]
    total = len(alive)
    centers = [node for node in alive
               if max([total - sizes[node]]
                      + [sizes[neighbor] for neighbor in adjacency[node]
                         if parent.get(neighbor) == node]) <= total // 2]

    def rooted(node, previous):
        return tuple(sorted(rooted(neighbor, node) for neighbor in adjacency[node]
                            if neighbor != previous))

    if len(centers) == 1:
        return ('r', rooted(centers[0], -1))
    first, second = centers[0], centers[1]
    return ('rr',) + tuple(sorted([rooted(first, second), rooted(second, first)]))


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        node_count = tokens[position]
        position += 1
        edges = []
        for _ in range(node_count - 1):
            first = tokens[position]
            second = tokens[position + 1]
            position += 2
            edges.append((first, second))
        if node_count == 1:
            answers.append("0")
            continue
        degree = [0] * node_count
        for first, second in edges:
            degree[first] += 1
            degree[second] += 1
        leaves = [node for node in range(node_count) if degree[node] == 1]
        forms = {canonical(node_count, edges, leaf) for leaf in leaves}
        answers.append(str(len(forms)))
    return '\n'.join(answers) + '\n'


SAMPLE = """5
4
0 1
0 2
0 3
4
0 1
1 3
3 2
6
0 2
1 2
2 3
3 5
3 4
7
1 2
0 1
2 3
2 4
3 5
6 5
9
0 1
1 2
2 3
3 4
4 5
2 6
3 7
4 8
"""
SAMPLE_OUT = """1
1
1
3
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
SAMPLE_TWO = """1
11
6 1
3 6
4 3
2 3
0 6
5 2
10 4
8 1
7 10
9 0
"""
assert oracle(SAMPLE_TWO) == "3\n"
assert oracle("4\n1\n2\n0 1\n3\n0 1\n1 2\n2\n0 1\n") == "0\n1\n1\n1\n"
assert oracle("1\n6\n0 1\n1 2\n2 3\n3 4\n4 5\n") == "1\n"
assert oracle("1\n6\n0 1\n0 2\n0 3\n3 4\n4 5\n") == "2\n"


def build_tree(rng, node_count, shape):
    edges = []
    if shape == 'star':
        edges = [(0, node) for node in range(1, node_count)]
    elif shape == 'path':
        edges = [(node, node + 1) for node in range(node_count - 1)]
    else:
        for node in range(1, node_count):
            parent = rng.randrange(node)
            edges.append((parent, node))
    return edges


def make_text(cases):
    lines = [str(len(cases))]
    for node_count, edges in cases:
        lines.append(str(node_count))
        for first, second in edges:
            lines.append(f"{first} {second}")
    return '\n'.join(lines) + '\n'


def write(name, cases):
    text = make_text(cases)
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    edges_cases = [(1, []), (2, [(0, 1)]), (3, [(0, 1), (1, 2)]),
                   (4, [(0, 1), (0, 2), (0, 3)]),
                   (5, [(0, 1), (1, 2), (2, 3), (3, 4)])]
    write("2_edges", edges_cases)
    write("3_wide", [(151, build_tree(random.Random(7), 151, 'star'))])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(6):
        node_count = rng.randint(20, 90)
        random_cases.append((node_count, build_tree(rng, node_count, 'random')))
    write("4_random", random_cases)
    io_cases = []
    for case_index in range(100):
        node_count = 20 + case_index % 11
        io_cases.append((node_count, build_tree(rng, node_count, 'random')))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
