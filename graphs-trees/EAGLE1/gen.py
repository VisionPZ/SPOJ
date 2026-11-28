#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_tree(node_count, edges):
    adjacency = [[] for _ in range(node_count + 1)]
    for first, second, dogs in edges:
        adjacency[first].append((second, dogs))
        adjacency[second].append((first, dogs))
    parent = [0] * (node_count + 1)
    order = [1]
    for node in order:
        for neighbor, _ in adjacency[node]:
            if neighbor != parent[node]:
                parent[neighbor] = node
                order.append(neighbor)
    downward = [0] * (node_count + 1)
    for node in reversed(order):
        best = 0
        for neighbor, dogs in adjacency[node]:
            if parent[neighbor] == node:
                best = max(best, dogs + downward[neighbor])
        downward[node] = best
    top_value = [0] * (node_count + 1)
    second_value = [0] * (node_count + 1)
    top_child = [0] * (node_count + 1)
    for node in order:
        for neighbor, dogs in adjacency[node]:
            if parent[neighbor] == node:
                value = dogs + downward[neighbor]
                if value > top_value[node]:
                    second_value[node] = top_value[node]
                    top_value[node] = value
                    top_child[node] = neighbor
                elif value > second_value[node]:
                    second_value[node] = value
    upward = [0] * (node_count + 1)
    for node in order:
        for neighbor, dogs in adjacency[node]:
            if parent[neighbor] == node:
                sibling_best = top_value[node] if neighbor != top_child[node] else second_value[node]
                upward[neighbor] = dogs + max(upward[node], sibling_best)
    return [max(downward[node], upward[node]) for node in range(1, node_count + 1)]


def brute_tree(node_count, edges):
    adjacency = [[] for _ in range(node_count + 1)]
    for first, second, dogs in edges:
        adjacency[first].append((second, dogs))
        adjacency[second].append((first, dogs))
    answers = []
    for start in range(1, node_count + 1):
        stack = [(start, 0, 0)]
        farthest = 0
        while stack:
            node, previous, distance = stack.pop()
            farthest = max(farthest, distance)
            for neighbor, dogs in adjacency[node]:
                if neighbor != previous:
                    stack.append((neighbor, node, distance + dogs))
        answers.append(farthest)
    return answers


def oracle_cases(cases):
    lines = []
    for node_count, edges in cases:
        lines.append(" ".join(str(value) for value in oracle_tree(node_count, edges)))
    return "\n".join(lines) + "\n"


SAMPLE_INPUT = "1\n4\n1 2 3\n3 2 4\n3 4 5\n"
SAMPLE_OUTPUT = "12 9 7 12\n"
assert oracle_cases([(4, [(1, 2, 3), (3, 2, 4), (3, 4, 5)])]) == SAMPLE_OUTPUT
assert oracle_tree(2, [(1, 2, 7)]) == [7, 7]
assert oracle_tree(3, [(1, 2, 1), (2, 3, 2)]) == [3, 2, 3]

rng = random.Random(20261126)
for _ in range(120):
    node_count = rng.randint(2, 12)
    edges = [(node, rng.randint(1, node - 1), rng.randint(1, 50))
             for node in range(2, node_count + 1)]
    assert oracle_tree(node_count, edges) == brute_tree(node_count, edges)


def random_tree(node_count, seed):
    local = random.Random(seed)
    return [(node, local.randint(1, node - 1), local.randint(1, 10**9))
            for node in range(2, node_count + 1)]


def chain_tree(node_count, dog_count):
    return [(node, node + 1, dog_count) for node in range(1, node_count)]


def write(name, cases, raw_input=None, raw_output=None):
    text = raw_input if raw_input is not None else str(len(cases)) + "".join(
        f"\n{node_count}" + "".join(
            f"\n{first} {second} {dogs}" for first, second, dogs in edges)
        for node_count, edges in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(
        raw_output if raw_output is not None else oracle_cases(cases))


def build():
    write("2_edges", [(2, [(1, 2, 1)]), (3, [(1, 2, 10**9), (1, 3, 10**9)]),
                      (5, chain_tree(5, 10**9))])
    write("3_wide", [(60, chain_tree(60, 10**9)),
                     (60, [(node, node // 2, 10**9) for node in range(2, 61)])])
    write("4_random", [(400, random_tree(400, 1000 + index)) for index in range(4)])
    write("5_io", [(100000, chain_tree(100000, 10**9)),
                   (100000, random_tree(100000, 20261126))])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [], raw_input=SAMPLE_INPUT, raw_output=SAMPLE_OUTPUT)
build()
