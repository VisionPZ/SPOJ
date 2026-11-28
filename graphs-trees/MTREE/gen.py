#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def oracle(text):
    tokens = list(map(int, text.split()))
    cursor = 0
    node_count = tokens[cursor]
    cursor += 1
    children = [[] for _ in range(node_count + 1)]
    children_weight = [0] * (node_count + 1)
    for _ in range(node_count - 1):
        first = tokens[cursor]
        second = tokens[cursor + 1]
        weight = tokens[cursor + 2]
        cursor += 3
        children[first].append((second, weight))
        children[second].append((first, weight))
    visited = {1}
    parent = [0] * (node_count + 1)
    order = []
    stack = [1]
    while stack:
        node = stack.pop()
        order.append(node)
        for neighbor, edge_weight in children[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                parent[neighbor] = node
                children_weight[neighbor] = edge_weight
                stack.append(neighbor)
    down_sum = [0] * (node_count + 1)
    up_sum = [0] * (node_count + 1)
    up_sum[1] = 1
    total = 0
    inverse_two = (MOD + 1) // 2
    for node in reversed(order):
        child_terms = []
        for neighbor, weight in children[node]:
            if parent[neighbor] == node:
                child_terms.append((weight * down_sum[neighbor]) % MOD)
        down_sum[node] = (1 + sum(child_terms)) % MOD
        squared_sum = sum(term * term for term in child_terms) % MOD
        term_sum = sum(child_terms) % MOD
        total = (total + (term_sum * term_sum - squared_sum) * inverse_two) % MOD
    for node in order:
        if node != 1:
            up_sum[node] = (children_weight[node] * up_sum[parent[node]] + 1) % MOD
            total = (total + up_sum[node] - 1) % MOD
    return str(total % MOD) + "\n"


def brute(text):
    tokens = list(map(int, text.split()))
    cursor = 0
    node_count = tokens[cursor]
    cursor += 1
    graph = [[] for _ in range(node_count + 1)]
    for _ in range(node_count - 1):
        first = tokens[cursor]
        second = tokens[cursor + 1]
        weight = tokens[cursor + 2]
        cursor += 3
        graph[first].append((second, weight))
        graph[second].append((first, weight))
    total = 0
    for start in range(1, node_count + 1):
        stack = [(start, 0, 1)]
        seen = {start}
        while stack:
            node, parent, product = stack.pop()
            if node > start:
                total += product
            for neighbor, weight in graph[node]:
                if neighbor != parent and neighbor not in seen:
                    seen.add(neighbor)
                    stack.append((neighbor, node, (product * weight) % MOD))
    return str(total % MOD) + "\n"


SAMPLE_ONE = """3
3 2 100
2 1 100
"""
SAMPLE_TWO = """4
1 2 5
1 3 5
1 4 5
"""
SAMPLE_THREE = """5
1 2 2
2 3 3
4 3 2
5 3 2
"""
assert oracle(SAMPLE_ONE) == "10200\n"
assert oracle(SAMPLE_TWO) == "90\n"
assert oracle(SAMPLE_THREE) == "55\n"
assert brute(SAMPLE_ONE) == "10200\n"
assert brute(SAMPLE_TWO) == "90\n"
assert brute(SAMPLE_THREE) == "55\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_tree(node_count, rng):
    lines = [str(node_count)]
    for node in range(2, node_count + 1):
        parent = rng.randint(1, node - 1)
        weight = rng.randint(0, 1000)
        lines.append(f"{parent} {node} {weight}")
    return "\n".join(lines) + "\n"


def build():
    write("2_edges", SAMPLE_TWO)
    write("3_wide", SAMPLE_THREE)
    rng = random.Random(20261126)
    small = make_tree(12, rng)
    assert brute(small) == oracle(small)
    write("4_random", small)
    write("5_io", make_tree(100000, rng))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_ONE)
build()
