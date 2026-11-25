#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]; cursor += 1
    answers = []
    for _ in range(case_count):
        vertex_count = tokens[cursor]; cursor += 1
        edges = []
        for _ in range(vertex_count - 1):
            first = tokens[cursor]; cursor += 1
            second = tokens[cursor]; cursor += 1
            edges.append((first - 1, second - 1))
        graph = [[] for _ in range(vertex_count)]
        for first, second in edges:
            graph[first].append(second)
            graph[second].append(first)
        best = 1
        for start in range(vertex_count):
            parent = [-1] * vertex_count
            parent[start] = start
            queue = deque([start])
            while queue:
                node = queue.popleft()
                path = []
                walker = node
                while walker != start:
                    path.append(walker + 1)
                    walker = parent[walker]
                path.append(start + 1)
                path.reverse()
                lengths = [1] * len(path)
                for right in range(len(path)):
                    for left in range(right):
                        if path[left] < path[right] and lengths[left] + 1 > lengths[right]:
                            lengths[right] = lengths[left] + 1
                best = max(best, max(lengths))
                for neighbor in graph[node]:
                    if parent[neighbor] == -1:
                        parent[neighbor] = node
                        queue.append(neighbor)
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """2
12
3 1
1 4
4 12
12 8
4 5
5 11
5 6
5 2
3 9
9 10
9 7
12
1 8
8 6
8 3
3 12
3 10
3 5
5 4
5 2
1 9
9 11
9 7
"""
SAMPLE_OUT = "4\n5\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n2\n1 2\n") == "2\n"
assert oracle("1\n3\n1 2\n2 3\n") == "3\n"
assert oracle("1\n4\n1 2\n1 3\n1 4\n") == "2\n"
assert 2 * 3 == 6


def case_text(vertex_count, edges):
    return str(vertex_count) + "\n" + "".join(f"{u} {v}\n" for u, v in edges)


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, vertex_count):
    edges = [(node, rng.randint(1, node - 1)) for node in range(2, vertex_count + 1)]
    return (vertex_count, edges)


def build():
    write("2_edges", [
        (1, []),
        (2, [(1, 2)]),
        (3, [(1, 2), (1, 3)]),
        (4, [(1, 2), (2, 3), (3, 4)]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 12) for _ in range(10)])
    write("4_random", [random_case(rng, rng.randint(2, 12)) for _ in range(40)])
    write("5_io", [random_case(rng, 12) for _ in range(400)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
