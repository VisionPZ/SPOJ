#!/usr/bin/env python3
import random
import sys
from pathlib import Path

sys.setrecursionlimit(200000)
ROOT = Path(__file__).resolve().parent


def canonical(n, edges, removed):
    adjacency = [[] for _ in range(n)]
    for first, second in edges:
        if first == removed or second == removed:
            continue
        adjacency[first].append(second)
        adjacency[second].append(first)
    alive = [node for node in range(n) if node != removed]
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
    node_count = tokens[0]
    edges = [(tokens[index], tokens[index + 1]) for index in range(1, 2 * node_count - 1, 2)]
    degree = [0] * node_count
    for first, second in edges:
        degree[first] += 1
        degree[second] += 1
    leaves = [node for node in range(node_count) if degree[node] == 1]
    forms = {canonical(node_count, edges, leaf) for leaf in leaves}
    return str(len(forms)) + '\n'


SAMPLE = """25
18 7
16 18
15 18
8 7
1 8
13 15
22 8
14 18
3 18
23 7
10 8
20 1
21 14
19 3
6 3
9 6
11 7
5 15
17 16
12 22
4 10
24 17
0 8
2 19
"""
SAMPLE_OUT = """7
"""
assert oracle(SAMPLE) == SAMPLE_OUT
SAMPLE_TWO = """25
6 17
2 6
1 2
13 6
7 6
3 17
16 17
12 7
21 2
0 3
9 12
20 6
8 13
22 2
14 21
19 21
18 21
11 6
10 13
24 19
4 16
5 1
23 10
15 20
"""
assert oracle(SAMPLE_TWO) == "10\n"


def build_tree(rng, node_count, shape):
    if shape == 'star':
        return [(0, node) for node in range(1, node_count)]
    if shape == 'path':
        return [(node, node + 1) for node in range(node_count - 1)]
    return [(rng.randrange(node), node) for node in range(1, node_count)]


def write(name, node_count, edges):
    text = str(node_count) + '\n' + '\n'.join(f"{first} {second}" for first, second in edges) + '\n'
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    write("2_edges", 25, build_tree(random.Random(1), 25, 'path'))
    write("3_wide", 1000, build_tree(random.Random(2), 1000, 'star'))
    rng = random.Random(20261126)
    write("4_random", 200, build_tree(rng, 200, 'random'))
    write("5_io", 2000, build_tree(rng, 2000, 'random'))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
