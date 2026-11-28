#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 18


def parse(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    cases = []
    while True:
        node_count = tokens[cursor]
        root_node = tokens[cursor + 1]
        cursor += 2
        if node_count == 0 and root_node == 0:
            break
        cost_factors = [0] + tokens[cursor:cursor + node_count]
        cursor += node_count
        parent_nodes = [0] * (node_count + 1)
        for _ in range(node_count - 1):
            father_node = tokens[cursor]
            child_node = tokens[cursor + 1]
            cursor += 2
            parent_nodes[child_node] = father_node
        cases.append((node_count, root_node, cost_factors, parent_nodes))
    return cases


def oracle(text):
    answers = []
    for node_count, root_node, cost_factors, parent_nodes in parse(text):
        dp = [INF] * (1 << node_count)
        dp[0] = 0
        for mask in range(1 << node_count):
            if dp[mask] == INF:
                continue
            finish_time = mask.bit_count() + 1
            for node in range(1, node_count + 1):
                bit = 1 << (node - 1)
                if mask & bit:
                    continue
                if node == root_node or (mask & (1 << (parent_nodes[node] - 1))):
                    next_mask = mask | bit
                    candidate = dp[mask] + cost_factors[node] * finish_time
                    if candidate < dp[next_mask]:
                        dp[next_mask] = candidate
        answers.append(str(dp[(1 << node_count) - 1]))
    return "\n".join(answers) + "\n"


def brute_case(node_count, root_node, cost_factors, parent_nodes):
    best = INF
    other_nodes = [node for node in range(1, node_count + 1) if node != root_node]
    for tail in itertools.permutations(other_nodes):
        colored = set()
        total = 0
        valid = True
        for finish_time, node in enumerate([root_node] + list(tail), start=1):
            if node != root_node and parent_nodes[node] not in colored:
                valid = False
                break
            total += cost_factors[node] * finish_time
            colored.add(node)
        if valid and total < best:
            best = total
    return best


SAMPLE = """5 1
1 2 1 2 4
1 2
1 3
2 4
3 5
0 0
"""
SAMPLE_OUT = """33
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_case(5, 1, [0, 1, 2, 1, 2, 4], [0, 0, 1, 1, 2, 3]) == 33
assert oracle("1 1\n7\n0 0\n") == "7\n"
assert oracle("2 2\n3 5\n2 1\n0 0\n") == "11\n"
assert oracle("2 1\n1 9\n1 2\n0 0\n") == "19\n"


def render(cases):
    lines = []
    for node_count, root_node, cost_factors, parent_nodes in cases:
        lines.append(f"{node_count} {root_node}")
        lines.append(" ".join(str(cost_factors[node]) for node in range(1, node_count + 1)))
        for node in range(1, node_count + 1):
            if node != root_node:
                lines.append(f"{parent_nodes[node]} {node}")
    lines.append("0 0")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, node_count):
    root_node = rng.randint(1, node_count)
    visited = [root_node]
    waiting = [node for node in range(1, node_count + 1) if node != root_node]
    rng.shuffle(waiting)
    parent_nodes = [0] * (node_count + 1)
    for node in waiting:
        parent_nodes[node] = rng.choice(visited)
        visited.append(node)
    cost_factors = [0] + [rng.randint(1, 500) for _ in range(node_count)]
    return (node_count, root_node, cost_factors, parent_nodes)


def build():
    edge_cases = [
        (1, 1, [0, 7], [0]),
        (2, 2, [0, 3, 5], [0, 2, 0]),
        (2, 1, [0, 1, 9], [0, 0, 1]),
        (3, 1, [0, 1, 2, 3], [0, 0, 1, 2]),
    ]
    write("2_edges", edge_cases)
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 12)])
    write("4_random", [random_case(rng, rng.randint(5, 12)) for _ in range(10)])
    write("5_io", [random_case(rng, rng.randint(6, 10)) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
