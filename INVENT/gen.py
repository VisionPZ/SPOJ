#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        node_count = tokens[cursor]
        cursor += 1
        adjacency = [[] for _ in range(node_count + 1)]
        tree_pairs = set()
        tree_weight_total = 0
        for _ in range(node_count - 1):
            first_node = tokens[cursor]
            second_node = tokens[cursor + 1]
            edge_weight = tokens[cursor + 2]
            cursor += 3
            adjacency[first_node].append((second_node, edge_weight))
            adjacency[second_node].append((first_node, edge_weight))
            tree_pairs.add(frozenset((first_node, second_node)))
            tree_weight_total += edge_weight
        total = tree_weight_total
        for first_node in range(1, node_count + 1):
            for second_node in range(first_node + 1, node_count + 1):
                if frozenset((first_node, second_node)) in tree_pairs:
                    continue
                stack = [(first_node, 0, 0)]
                best_weight = 0
                while stack:
                    current_node, previous_node, heaviest = stack.pop()
                    if current_node == second_node:
                        best_weight = heaviest
                        break
                    for neighbor, weight in adjacency[current_node]:
                        if neighbor != previous_node:
                            stack.append((neighbor, current_node, max(heaviest, weight)))
                total += best_weight + 1
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = """2

3
1 2 4
2 3 7

4
1 2 1
1 3 1
1 4 2
"""
SAMPLE_OUT = """19
12
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "0\n"
assert oracle("1\n2\n1 2 5\n") == "5\n"
assert oracle("1\n4\n1 2 3\n2 3 3\n3 4 3\n") == "21\n"
assert oracle("1\n4\n1 2 1\n1 3 1\n1 4 1\n") == "9\n"


def write(name, cases):
    parts = [str(len(cases))]
    for node_count, edges in cases:
        parts.append(str(node_count))
        parts.extend(f"{first} {second} {weight}" for first, second, weight in edges)
    text = "\n\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_tree(node_count, rng, weight_limit):
    return [(parent, child, rng.randint(1, weight_limit))
            for child in range(2, node_count + 1)
            for parent in [rng.randint(1, child - 1)]]


def build():
    write("2_edges", [
        (1, []),
        (2, [(1, 2, 1)]),
        (5, [(1, 2, 1), (1, 3, 1), (1, 4, 1), (1, 5, 1)]),
        (5, [(1, 2, 7), (2, 3, 7), (3, 4, 7), (4, 5, 7)]),
    ])
    rng = random.Random(20261127)
    write("3_wide", [(200, random_tree(200, rng, 10000)) for _ in range(3)])
    random_cases = []
    for _ in range(12):
        nodes = rng.randint(2, 45)
        random_cases.append((nodes, random_tree(nodes, rng, 10000)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(240):
        nodes = rng.randint(2, 20)
        io_cases.append((nodes, random_tree(nodes, rng, 10000)))
    write("5_io", io_cases)

    big_rng = random.Random(20261128)
    big_edges = random_tree(15000, big_rng, 10000)
    big_parts = ["1", "15000"]
    big_parts.extend(f"{first} {second} {weight}" for first, second, weight in big_edges)
    Path("/tmp/INVENT_big.txt").write_text("\n".join(big_parts) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
