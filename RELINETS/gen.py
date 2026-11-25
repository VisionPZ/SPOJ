#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def connected(node_count, adjacency):
    reached = {0}
    stack = [0]
    while stack:
        current = stack.pop()
        for neighbor, multiplicity in adjacency[current].items():
            if multiplicity and neighbor not in reached:
                reached.add(neighbor)
                stack.append(neighbor)
    return len(reached) == node_count


def is_reliable(node_count, edges, chosen):
    if node_count == 1:
        return True
    adjacency = [{} for _ in range(node_count)]
    for index in chosen:
        left, right, _ = edges[index]
        adjacency[left][right] = adjacency[left].get(right, 0) + 1
        adjacency[right][left] = adjacency[right].get(left, 0) + 1
    if not connected(node_count, adjacency):
        return False
    for index in chosen:
        left, right, _ = edges[index]
        adjacency[left][right] -= 1
        adjacency[right][left] -= 1
        survived = connected(node_count, adjacency)
        adjacency[left][right] += 1
        adjacency[right][left] += 1
        if not survived:
            return False
    return True


def oracle_case(node_count, edges):
    best = None
    for chosen in itertools.chain.from_iterable(itertools.combinations(range(len(edges)), size) for size in range(len(edges) + 1)):
        price = sum(edges[index][2] for index in chosen)
        if best is not None and price >= best:
            continue
        if is_reliable(node_count, edges, chosen):
            best = price
    return best


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    answers = []
    while position < len(tokens):
        node_count = tokens[position]
        edge_count = tokens[position + 1]
        position += 2
        if node_count == 0 and edge_count == 0:
            break
        edges = []
        for _ in range(edge_count):
            edges.append((tokens[position] - 1, tokens[position + 1] - 1, tokens[position + 2]))
            position += 3
        best = oracle_case(node_count, edges)
        if best is None:
            answers.append(f"There is no reliable net possible for test case {len(answers) + 1}.")
        else:
            answers.append(f"The minimal cost for test case {len(answers) + 1} is {best}.")
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """4 5
1 2 1
1 3 2
2 4 2
3 4 1
2 3 1
2 1
1 2 5
0 0
"""
SAMPLE_OUT = """The minimal cost for test case 1 is 6.
There is no reliable net possible for test case 2.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(3, [(0, 1, 1), (1, 2, 1), (2, 0, 1)]) == 3
assert oracle_case(3, [(0, 1, 1), (1, 2, 1)]) is None
assert oracle_case(4, [(0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 0, 1)]) == 4
assert oracle_case(2, [(0, 1, 5), (0, 1, 7)]) == 12


def write_case(name, cases):
    lines = []
    for node_count, edges in cases:
        lines.append(f"{node_count} {len(edges)}\n")
        lines.extend(f"{left + 1} {right + 1} {price}\n" for left, right, price in edges)
    lines.append("0 0\n")
    text = "".join(lines)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        (1, []),
        (2, [(0, 1, 5)]),
        (2, [(0, 1, 5), (0, 1, 7)]),
        (3, [(0, 1, 4), (1, 2, 4)]),
        (4, [(0, 1, 1), (1, 2, 2), (2, 3, 3), (3, 0, 4), (0, 2, 5)]),
    ])
    rng = random.Random(20261126)
    edges = set()
    while len(edges) < 14:
        left = rng.randint(0, 10)
        right = rng.randint(0, 10)
        if left != right:
            edges.add((min(left, right), max(left, right), rng.randint(1, 199)))
    write_case("3_wide", [(11, sorted(edges))])
    cases = []
    for _ in range(15):
        node_count = rng.randint(3, 8)
        edge_count = rng.randint(0, 12)
        cases.append((node_count, [(rng.randint(0, node_count - 1), rng.randint(0, node_count - 1), rng.randint(1, 30)) for _ in range(edge_count)]))
    write_case("4_random", cases)
    rng = random.Random(310229)
    cases = []
    for _ in range(300):
        node_count = rng.randint(3, 6)
        edge_count = rng.randint(3, 7)
        cases.append((node_count, [(rng.randint(0, node_count - 1), rng.randint(0, node_count - 1), rng.randint(1, 40)) for _ in range(edge_count)]))
    write_case("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
