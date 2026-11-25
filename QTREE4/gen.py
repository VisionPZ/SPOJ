#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(node_count, edges, operations):
    adjacency = [[] for _ in range(node_count + 1)]
    for first, second, weight in edges:
        adjacency[first].append((second, weight))
        adjacency[second].append((first, weight))
    white = set(range(1, node_count + 1))
    answers = []
    for operation in operations:
        if operation[0] == "C":
            node = operation[1]
            if node in white:
                white.remove(node)
            else:
                white.add(node)
            continue
        if not white:
            answers.append("They have disappeared.")
            continue
        best = 0
        for source in white:
            distances = {source: 0}
            stack = [source]
            while stack:
                current = stack.pop()
                for neighbor, weight in adjacency[current]:
                    if neighbor not in distances:
                        distances[neighbor] = distances[current] + weight
                        stack.append(neighbor)
            for target in white:
                value = distances[target]
                if value > best:
                    best = value
        answers.append(str(best))
    return "\n".join(answers) + "\n" if answers else ""


def encode(node_count, edges, operations):
    lines = [str(node_count)]
    lines.extend(f"{first} {second} {weight}" for first, second, weight in edges)
    lines.append(str(len(operations)))
    lines.extend("C " + str(operation[1]) if operation[0] == "C" else "A"
                 for operation in operations)
    return "\n".join(lines) + "\n"


SAMPLE = (3, [(1, 2, 1), (1, 3, 1)],
          [("A", 0), ("C", 1), ("A", 0), ("C", 2), ("A", 0), ("C", 3), ("A", 0)])
assert oracle(*SAMPLE) == "2\n2\n0\nThey have disappeared.\n"
assert encode(*SAMPLE) == "3\n1 2 1\n1 3 1\n7\nA\nC 1\nA\nC 2\nA\nC 3\nA\n"
assert oracle(1, [], [("A", 0), ("C", 1), ("A", 0)]) == "0\nThey have disappeared.\n"
assert oracle(2, [(1, 2, -5)], [("A", 0), ("C", 2), ("A", 0)]) == "0\n0\n"


def write(name, node_count, edges, operations):
    text = encode(node_count, edges, operations)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(node_count, edges, operations))


def build():
    rng = random.Random(20261126)
    write("2_edges", 1, [], [("A", 0), ("C", 1), ("A", 0), ("C", 1), ("A", 0)])
    edges = [(1, 2, -5), (1, 3, 7), (3, 4, -2), (4, 5, 9)]
    operations = [("C", node) for node in (2, 4)] + [("A", 0)] + \
                 [("C", node) for node in (1, 3, 5)] + [("A", 0)]
    write("3_wide", 5, edges, operations)
    edges = []
    for node in range(2, 9):
        edges.append((rng.randint(1, node - 1), node, rng.randint(-1000, 1000)))
    operations = []
    for _ in range(120):
        if rng.random() < 0.55:
            operations.append(("C", rng.randint(1, 8)))
        else:
            operations.append(("A", 0))
    write("4_random", 8, edges, operations)
    edges = []
    for node in range(2, 13):
        edges.append((rng.randint(1, node - 1), node, rng.randint(-1000, 1000)))
    operations = []
    for _ in range(400):
        if rng.random() < 0.5:
            operations.append(("C", rng.randint(1, 12)))
        else:
            operations.append(("A", 0))
    write("5_io", 12, edges, operations)
    big_edges = []
    for node in range(2, 100001):
        big_edges.append((rng.randint(1, node - 1), node, rng.randint(-1000, 1000)))
    big_operations = []
    for _ in range(100000):
        if rng.random() < 0.5:
            big_operations.append(("C", rng.randint(1, 100000)))
        else:
            big_operations.append(("A", 0))
    Path("/tmp/QTREE4_big.txt").write_text(encode(100000, big_edges, big_operations))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", *SAMPLE)
build()
