#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**9


def oracle(vertex_count, sources, targets, edges):
    bottleneck = [[INF] * vertex_count for _ in range(vertex_count)]
    for source in sources:
        bottleneck[source][source] = 0
    for first, second, energy in edges:
        bottleneck[first][second] = min(bottleneck[first][second], energy)
    for via in range(vertex_count):
        for first in range(vertex_count):
            if bottleneck[first][via] == INF:
                continue
            for second in range(vertex_count):
                candidate = max(bottleneck[first][via], bottleneck[via][second])
                if candidate < bottleneck[first][second]:
                    bottleneck[first][second] = candidate

    best_bound = []
    for target in targets:
        bound = min(bottleneck[source][target] for source in sources)
        if bound == INF:
            return "Excessive Energy."
        best_bound.append(bound)
    upper = max(best_bound) if best_bound else 0

    step_count = [[INF] * vertex_count for _ in range(vertex_count)]
    for first in range(vertex_count):
        step_count[first][first] = 0
    for first, second, energy in edges:
        if energy <= upper:
            step_count[first][second] = min(step_count[first][second], 1)
    for via in range(vertex_count):
        for first in range(vertex_count):
            if step_count[first][via] == INF:
                continue
            for second in range(vertex_count):
                if step_count[via][second] == INF:
                    continue
                candidate = step_count[first][via] + step_count[via][second]
                if candidate < step_count[first][second]:
                    step_count[first][second] = candidate

    conversions = sum(min(step_count[source][target] for source in sources)
                      for target in targets)
    return f"{upper} {conversions}"


def solve_text(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        source_count = int(tokens[cursor]); cursor += 1
        target_count = int(tokens[cursor]); cursor += 1
        vertex_count = int(tokens[cursor]); cursor += 1
        sources = [int(tokens[cursor + index]) for index in range(source_count)]
        cursor += source_count
        targets = [int(tokens[cursor + index]) for index in range(target_count)]
        cursor += target_count
        edge_count = int(tokens[cursor]); cursor += 1
        edges = []
        for _ in range(edge_count):
            first = int(tokens[cursor]); cursor += 1
            second = int(tokens[cursor]); cursor += 1
            energy = int(tokens[cursor]); cursor += 1
            edges.append((first, second, energy))
        answers.append(oracle(vertex_count, sources, targets, edges))
    return "\n".join(answers) + "\n"


SAMPLE = """1
2 2 6
1
3
0
3
6
1 2 2
2 4 3
4 5 1
4 2 2
3 0 4
5 0 1
"""
SAMPLE_OUT = "3 4\n"
assert solve_text(SAMPLE) == SAMPLE_OUT
assert oracle(2, [0], [1], [(0, 1, 7)]) == "7 1"
assert oracle(2, [0], [1], []) == "Excessive Energy."
assert oracle(3, [0, 1], [2], [(0, 2, 5), (1, 2, 3)]) == "3 1"
assert oracle(4, [0], [1, 2, 3], [(0, 1, 2), (1, 2, 4), (2, 3, 1), (0, 3, 9)]) == "4 6"


def write(name, cases):
    lines = [str(len(cases))]
    for vertex_count, sources, targets, edges in cases:
        lines.append(f"{len(sources)} {len(targets)} {vertex_count}")
        lines.extend(str(value) for value in sources)
        lines.extend(str(value) for value in targets)
        lines.append(str(len(edges)))
        lines.extend(f"{first} {second} {energy}" for first, second, energy in edges)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(solve_text(text))


def random_case(rng, vertex_count):
    sources = rng.sample(range(vertex_count), rng.randint(1, 3))
    targets = rng.sample(range(vertex_count), rng.randint(1, 3))
    edges = []
    for _ in range(rng.randint(2, vertex_count * 3)):
        edges.append((rng.randrange(vertex_count), rng.randrange(vertex_count),
                      rng.randint(1, 1000000000)))
    return vertex_count, sources, targets, edges


def build():
    write("2_edges", [
        (2, [0], [1], [(0, 1, 7)]),
        (2, [0], [1], []),
        (3, [0, 1], [2], [(0, 2, 5), (1, 2, 3)]),
        (4, [0], [1, 2, 3], [(0, 1, 2), (1, 2, 4), (2, 3, 1), (0, 3, 9)]),
        (5, [0], [4], [(0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 4, 1)]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 10) for _ in range(20)])
    write("4_random", [random_case(rng, rng.randint(3, 12)) for _ in range(60)])
    write("5_io", [random_case(rng, 8) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
