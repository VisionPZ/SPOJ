#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(town_count, reach_limit, edges):
    adjacency = [[] for _ in range(town_count)]
    for first, second in edges:
        adjacency[first].append(second)
        adjacency[second].append(first)

    def path_cost(path_nodes):
        distance = [-1] * town_count
        queue = deque()
        for node in path_nodes:
            distance[node] = 0
            queue.append(node)
        while queue:
            current = queue.popleft()
            for neighbor in adjacency[current]:
                if distance[neighbor] < 0:
                    distance[neighbor] = distance[current] + 1
                    queue.append(neighbor)
        return sum(distance)

    best_cost = None
    for start in range(town_count):
        stack = [(start, (start,))]
        while stack:
            current, path_nodes = stack.pop()
            cost = path_cost(path_nodes)
            if best_cost is None or cost < best_cost:
                best_cost = cost
            if len(path_nodes) - 1 < reach_limit:
                for neighbor in adjacency[current]:
                    if neighbor not in path_nodes:
                        stack.append((neighbor, path_nodes + (neighbor,)))
    return best_cost if best_cost is not None else 0


def solve_text(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        town_count = int(tokens[cursor]); cursor += 1
        reach_limit = int(tokens[cursor]); cursor += 1
        edges = []
        for _ in range(town_count - 1):
            first = int(tokens[cursor]); cursor += 1
            second = int(tokens[cursor]); cursor += 1
            edges.append((first, second))
        answers.append(str(oracle(town_count, reach_limit, edges)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3 1
0 1
1 2
4 1
0 1
1 2
2 3
"""
SAMPLE_OUT = "1\n2\n"
assert solve_text(SAMPLE) == SAMPLE_OUT
assert oracle(1, 1, []) == 0
assert oracle(3, 1, [(0, 1), (1, 2)]) == 1
assert oracle(4, 1, [(0, 1), (1, 2), (2, 3)]) == 2
assert oracle(5, 100, [(0, 1), (1, 2), (2, 3), (3, 4)]) == 0


def write(name, cases):
    lines = [str(len(cases))]
    for town_count, reach_limit, edges in cases:
        lines.append(f"{town_count} {reach_limit}")
        lines.extend(f"{first} {second}" for first, second in edges)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(solve_text(text))


def random_tree(town_count, rng):
    return [(rng.randrange(index), index) for index in range(1, town_count)]


def random_tree_case(rng):
    town_count = rng.randint(2, 9)
    return town_count, rng.randint(1, 6), random_tree(town_count, rng)


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        (1, 1, []),
        (2, 1, [(0, 1)]),
        (3, 1, [(0, 1), (1, 2)]),
        (5, 1, [(0, 1), (0, 2), (0, 3), (0, 4)]),
        (6, 2, [(0, 1), (1, 2), (1, 3), (3, 4), (3, 5)]),
    ])
    write("3_wide", [(9, 100, random_tree(9, rng)) for _ in range(15)])
    write("4_random", [random_tree_case(rng) for _ in range(60)])
    write("5_io", [(7, rng.randint(1, 6), random_tree(7, rng)) for _ in range(30)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
