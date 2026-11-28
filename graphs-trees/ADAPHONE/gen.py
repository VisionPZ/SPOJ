#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    node_count = int(tokens[0])
    query_count = int(tokens[1])
    cursor = 2
    adjacency = [[] for _ in range(node_count + 1)]
    for _ in range(node_count - 1):
        first = int(tokens[cursor])
        second = int(tokens[cursor + 1])
        cursor += 2
        adjacency[first].append(second)
        adjacency[second].append(first)
    answers = []
    for _ in range(query_count):
        start = int(tokens[cursor])
        finish = int(tokens[cursor + 1])
        cursor += 2
        parent = {start: 0}
        queue = deque([start])
        while queue and finish not in parent:
            current = queue.popleft()
            for neighbor in adjacency[current]:
                if neighbor not in parent:
                    parent[neighbor] = current
                    queue.append(neighbor)
        path = set()
        current = finish
        while current:
            path.add(current)
            current = parent[current]
        pair_count = sum(1 for value in path if value + 1 in path)
        answers.append(str(len(path) - pair_count))
    return "\n".join(answers) + "\n"


SAMPLE = """7 6
1 6
1 3
3 5
5 7
3 2
2 4
6 7
1 4
2 5
4 7
3 1
5 5
"""
SAMPLE_OUT = """3
1
2
2
2
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("6 5\n1 4\n4 6\n1 2\n2 5\n2 3\n6 5\n6 3\n3 5\n2 6\n4 5\n") == "2\n2\n2\n3\n2\n"
assert oracle("1 1\n1 1\n") == "1\n"
assert oracle("3 2\n1 2\n2 3\n1 3\n2 2\n") == "1\n1\n"


def write(name, edges, queries):
    text = f"{len(edges) + 1} {len(queries)}\n"
    text += "\n".join(f"{first} {second}" for first, second in edges) + "\n"
    text += "\n".join(f"{first} {second}" for first, second in queries) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_tree(rng, count):
    return [(child, rng.randint(1, child - 1)) for child in range(2, count + 1)]


def random_queries(rng, count, node_count):
    return [(rng.randint(1, node_count), rng.randint(1, node_count)) for _ in range(count)]


def build():
    rng = random.Random(20261126)
    write("2_edges", [(1, 2), (2, 3), (3, 4)], [(1, 1), (1, 2), (1, 4), (4, 1), (2, 3)])
    write("3_wide", random_tree(rng, 120), random_queries(rng, 80, 120))
    write("4_random", random_tree(rng, 180), random_queries(rng, 100, 180))
    write("5_io", random_tree(rng, 200), random_queries(rng, 200, 200))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
edges = [(1, 6), (1, 3), (3, 5), (5, 7), (3, 2), (2, 4)]
queries = [(6, 7), (1, 4), (2, 5), (4, 7), (3, 1), (5, 5)]
write("1_sample", edges, queries)
build()
