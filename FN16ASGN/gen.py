#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**9


def floyd_warshall(node_count, edges):
    dist = [[INF] * node_count for _ in range(node_count)]
    for index in range(node_count):
        dist[index][index] = 0
    for source, target, length in edges:
        dist[source][target] = min(dist[source][target], length)
    for middle in range(node_count):
        for source in range(node_count):
            for target in range(node_count):
                if dist[source][middle] + dist[middle][target] < dist[source][target]:
                    dist[source][target] = dist[source][middle] + dist[middle][target]
    return dist


def oracle_case(node_count, branch_count, group_count, edges):
    dist = floyd_warshall(node_count, edges)
    headquarters = branch_count
    costs = [dist[headquarters][branch] + dist[branch][headquarters]
             for branch in range(branch_count)]
    best = None
    for assignment in itertools.product(range(group_count), repeat=branch_count):
        if len(set(assignment)) != group_count:
            continue
        total = 0
        for group in range(group_count):
            members = [cost for branch, cost in enumerate(costs) if assignment[branch] == group]
            total += (len(members) - 1) * sum(members)
        if best is None or total < best:
            best = total
    return str(best)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    outputs = []
    while pos < len(tokens):
        node_count = tokens[pos]
        branch_count = tokens[pos + 1]
        group_count = tokens[pos + 2]
        road_count = tokens[pos + 3]
        pos += 4
        edges = []
        for _ in range(road_count):
            edges.append((tokens[pos] - 1, tokens[pos + 1] - 1, tokens[pos + 2]))
            pos += 3
        outputs.append(oracle_case(node_count, branch_count, group_count, edges))
    return "\n".join(outputs) + "\n"


SAMPLE = """5 4 2 10
5 2 1
2 5 1
3 5 5
4 5 0
1 5 1
2 3 1
3 2 5
2 4 5
2 1 1
3 4 2
5 4 2 10
5 2 1
2 5 1
3 5 5
4 5 10
1 5 1
2 3 1
3 2 5
2 4 5
2 1 1
3 4 2
"""
SAMPLE_OUT = """13
24
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(3, 2, 1, [(0, 2, 2), (1, 2, 3), (2, 0, 2), (2, 1, 3)]) == "10"
assert oracle_case(4, 3, 2, [(0, 3, 1), (1, 3, 2), (2, 3, 3), (3, 0, 1), (3, 1, 2), (3, 2, 3)]) == "6"
assert oracle_case(4, 3, 3, [(0, 3, 1), (1, 3, 2), (2, 3, 3), (3, 0, 1), (3, 1, 2), (3, 2, 3)]) == "0"


def case_text(node_count, branch_count, group_count, edges):
    lines = [f"{node_count} {branch_count} {group_count} {len(edges)}"]
    lines.extend(f"{source + 1} {target + 1} {length}" for source, target, length in edges)
    return "\n".join(lines) + "\n"


def random_case(rng, node_count, branch_count, group_count):
    edges = set()
    for index in range(node_count):
        edges.add((index, (index + 1) % node_count, rng.randint(0, 9)))
    for _ in range(rng.randint(node_count, 3 * node_count)):
        source = rng.randrange(node_count)
        target = rng.randrange(node_count)
        if source != target:
            edges.add((source, target, rng.randint(0, 9)))
    return node_count, branch_count, group_count, sorted(edges)


def write(name, cases):
    text = "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(3, 2, 1, [(0, 2, 2), (1, 2, 3), (2, 0, 2), (2, 1, 3)]),
                      (4, 3, 3, [(0, 3, 1), (1, 3, 2), (2, 3, 3),
                                 (3, 0, 1), (3, 1, 2), (3, 2, 3)])])
    rng = random.Random(20261126)
    wide = [random_case(rng, 8, 7, rng.randint(1, 4)) for _ in range(2)]
    write("3_wide", wide)
    rng = random.Random(20261127)
    random_cases = []
    for _ in range(4):
        node_count = rng.randint(4, 8)
        branch_count = rng.randint(2, node_count - 1)
        group_count = rng.randint(1, branch_count)
        random_cases.append(random_case(rng, node_count, branch_count, group_count))
    write("4_random", random_cases)
    rng = random.Random(20261128)
    io_cases = []
    for _ in range(12):
        node_count = rng.randint(3, 7)
        branch_count = rng.randint(2, node_count - 1)
        group_count = rng.randint(1, branch_count)
        io_cases.append(random_case(rng, node_count, branch_count, group_count))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_edges = [(4, 1, 1), (1, 4, 1), (2, 4, 5), (3, 4, 0), (0, 4, 1),
                (1, 2, 1), (2, 1, 5), (1, 3, 5), (1, 0, 1), (2, 3, 2)]
write("1_sample", [(5, 4, 2, sample_edges),
                   (5, 4, 2, [(source, target, 10 if (source, target) == (3, 4) else length)
                              for source, target, length in sample_edges])])
build()
