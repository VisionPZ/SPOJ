#!/usr/bin/env python3
import random
from collections import deque
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def edmonds_karp(flow_graph, source, sink):
    node_count = len(flow_graph)
    total = 0
    while True:
        parent = [-1] * node_count
        parent[source] = -2
        queue = deque([source])
        while queue and parent[sink] == -1:
            node = queue.popleft()
            for neighbor in range(node_count):
                if flow_graph[node][neighbor] > 0 and parent[neighbor] == -1:
                    parent[neighbor] = node
                    queue.append(neighbor)
                    if neighbor == sink:
                        break
        if parent[sink] == -1:
            return total
        pushed = node_count
        node = sink
        while node != source:
            previous = parent[node]
            pushed = min(pushed, flow_graph[previous][node])
            node = previous
        node = sink
        while node != source:
            previous = parent[node]
            flow_graph[previous][node] -= pushed
            flow_graph[node][previous] += pushed
            node = previous
        total += pushed


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    results = []
    while position < len(tokens):
        guard_count = tokens[position]
        friend_count = tokens[position + 1]
        position += 2
        if guard_count == 0 and friend_count == 0:
            break
        beliefs = tokens[position:position + guard_count]
        position += guard_count
        node_count = guard_count + 2
        source = 0
        sink = guard_count + 1
        graph = [[0] * node_count for _ in range(node_count)]
        for index, belief in enumerate(beliefs):
            if belief == 1:
                graph[source][index + 1] += 1
            else:
                graph[index + 1][sink] += 1
        for _ in range(friend_count):
            first = tokens[position]
            second = tokens[position + 1]
            position += 2
            graph[first][second] += 1
            graph[second][first] += 1
        results.append(str(edmonds_karp(graph, source, sink)))
    return "\n".join(results) + "\n"


def brute(guard_count, beliefs, pairs):
    best = guard_count + len(pairs)
    for votes in product((0, 1), repeat=guard_count):
        cost = sum(vote != belief for vote, belief in zip(votes, beliefs))
        cost += sum(votes[first - 1] != votes[second - 1] for first, second in pairs)
        best = min(best, cost)
    return best


def graph_text(guard_count, beliefs, pairs):
    lines = [f"{guard_count} {len(pairs)}", " ".join(map(str, beliefs))]
    lines += [f"{first} {second}" for first, second in pairs]
    return "\n".join(lines) + "\n"


SAMPLE = """3 3
1 0 0
1 2
1 3
3 2
6 6
1 1 1 0 0 0
1 2
2 3
4 2
3 5
4 5
5 6
0 0
"""
SAMPLE_OUT = """1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 0\n1 0\n0 0\n") == "0\n"
assert oracle("4 0\n0 0 0 0\n0 0\n") == "0\n"
assert brute(3, [1, 0, 0], [(1, 2), (1, 3)]) == 1
assert brute(4, [1, 1, 0, 0], [(1, 2), (2, 3), (3, 4)]) == 1

rng = random.Random(20261126)
for _ in range(40):
    count = rng.randint(2, 7)
    beliefs = [rng.randint(0, 1) for _ in range(count)]
    pairs = []
    for first in range(1, count + 1):
        for second in range(first + 1, count + 1):
            if rng.random() < 0.4:
                pairs.append((first, second))
    text = graph_text(count, beliefs, pairs) + "0 0\n"
    assert oracle(text) == str(brute(count, beliefs, pairs)) + "\n"


def write(name, cases):
    text = "".join(graph_text(count, beliefs, pairs) for count, beliefs, pairs in cases)
    text += "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (2, [0, 0], []),
        (2, [1, 0], [(1, 2)]),
        (3, [1, 1, 1], [(1, 2), (2, 3)]),
    ])
    count = 120
    beliefs = [index % 2 for index in range(count)]
    pairs = [(first, second) for first in range(1, count + 1)
             for second in range(first + 1, count + 1)
             if (first + second) % 3 == 0]
    write("3_wide", [(count, beliefs, pairs)])
    mixed = []
    for _ in range(12):
        size = rng.randint(20, 80)
        choices = [rng.randint(0, 1) for _ in range(size)]
        edges = [(rng.randint(1, size), rng.randint(1, size)) for _ in range(size * 4)]
        edges = [(first, second) for first, second in edges if first != second]
        mixed.append((size, choices, edges))
    write("4_random", mixed)
    medium = 60
    beliefs = [1 if index < medium // 2 else 0 for index in range(medium)]
    pairs = [(first, second) for first in range(1, medium + 1)
             for second in range(first + 1, min(medium, first + 12) + 1)]
    write("5_io", [(medium, beliefs, pairs)] * 200)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
