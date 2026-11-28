#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**30


def ferry(needed, length, capacity):
    if needed == 0:
        return length
    if 2 * length >= capacity:
        if needed + length > capacity:
            return INF
        return needed + length
    final_load = capacity - length
    if needed <= final_load:
        return needed + length
    deposit = capacity - 2 * length
    trips = (needed - final_load + deposit - 1) // deposit
    return needed + length + 2 * length * trips


def bellman_ford(nodes, edges, capacity):
    needed = [INF] * (nodes + 1)
    needed[nodes] = 0
    for _ in range(nodes):
        changed = False
        for first, second, length in edges:
            if length > capacity:
                continue
            for source, target in ((first, second), (second, first)):
                if needed[target] >= INF:
                    continue
                candidate = ferry(needed[target], length, capacity)
                if candidate < needed[source]:
                    needed[source] = candidate
                    changed = True
        if not changed:
            break
    return -1 if needed[1] >= INF else needed[1]


def brute_paths(nodes, edges, capacity):
    adjacency = [[] for _ in range(nodes + 1)]
    for first, second, length in edges:
        if length <= capacity:
            adjacency[first].append((second, length))
            adjacency[second].append((first, length))
    best = [INF]

    def walk(point, visited, suffix_cost):
        if point == 1:
            best[0] = min(best[0], suffix_cost)
            return
        for neighbor, length in adjacency[point]:
            if neighbor not in visited:
                walk(neighbor, visited | {neighbor}, ferry(suffix_cost, length, capacity))

    walk(nodes, {nodes}, 0)
    return -1 if best[0] >= INF else best[0]


def oracle(text):
    tokens = [int(token) for token in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        nodes = tokens[cursor]
        path_count = tokens[cursor + 1]
        capacity = tokens[cursor + 2]
        cursor += 3
        edges = []
        for _ in range(path_count):
            first = tokens[cursor]
            second = tokens[cursor + 1]
            length = tokens[cursor + 2]
            cursor += 3
            edges.append((first, second, length))
        answers.append(str(bellman_ford(nodes, edges, capacity)))
    return "\n".join(answers) + "\n"


SAMPLE = """1
9 10 25
1 2 3
2 3 12
3 4 4
3 5 9
4 9 13
5 9 5
2 6 10
6 7 10
7 8 10
8 9 10
"""
SAMPLE_OUT = """65
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1 5\n1 2 5\n") == "5\n"
assert oracle("1\n2 1 4\n1 2 5\n") == "-1\n"
assert oracle("1\n1 0 0\n") == "0\n"
assert ferry(0, 3, 5) == 3
assert ferry(50, 3, 25) == 65
rng_check = random.Random(87)
for _ in range(300):
    nodes = rng_check.randint(2, 6)
    capacity = rng_check.randint(0, 9)
    edges = []
    for first in range(1, nodes + 1):
        for second in range(first + 1, nodes + 1):
            if rng_check.random() < 0.5:
                edges.append((first, second, rng_check.randint(0, 9)))
    assert bellman_ford(nodes, edges, capacity) == brute_paths(nodes, edges, capacity)


def write_case(name, cases):
    chunks = [str(len(cases))]
    for nodes, edges, capacity in cases:
        chunks.append(f"{nodes} {len(edges)} {capacity}")
        chunks.extend(f"{first} {second} {length}" for first, second, length in edges)
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        (2, [(1, 2, 0)], 0),
        (2, [(1, 2, 1)], 1),
        (3, [(1, 2, 4)], 3),
        (4, [(1, 2, 2), (2, 4, 2), (1, 3, 9)], 4),
        (5, [(1, 2, 3), (2, 3, 3), (3, 5, 3), (2, 4, 1), (4, 5, 1)], 6),
    ])
    rng = random.Random(20261126)
    chain = [(point, point + 1, rng.randint(1, 20)) for point in range(1, 99)]
    write_case("3_wide", [(99, chain, 99)])
    random_cases = []
    for _ in range(20):
        nodes = rng.randint(2, 30)
        capacity = rng.randint(1, 40)
        edges = []
        for _ in range(rng.randint(1, 45)):
            first = rng.randint(1, nodes)
            second = rng.randint(1, nodes)
            if first != second:
                edges.append((first, second, rng.randint(0, 45)))
        random_cases.append((nodes, edges, capacity))
    write_case("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        nodes = 99
        capacity = 99
        edges = [(point, point + 1, 1) for point in range(1, 99)]
        edges.extend((rng.randint(1, 90), rng.randint(2, 99), rng.randint(1, 30))
                     for _ in range(40))
        io_cases.append((nodes, edges, capacity))
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
