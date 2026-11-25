#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_importance(node_count, adjacency):
    best = [[10**9] * node_count for _ in range(node_count)]
    counts = [[0] * node_count for _ in range(node_count)]
    through = [[[0] * node_count for _ in range(node_count)] for _ in range(node_count)]

    for source in range(node_count):
        def walk(node, distance, mask):
            if node != source:
                if distance < best[source][node]:
                    best[source][node] = distance
                    counts[source][node] = 1
                    for vertex in range(node_count):
                        through[vertex][source][node] = 0
                elif distance == best[source][node]:
                    counts[source][node] += 1
                if distance == best[source][node]:
                    for vertex in range(node_count):
                        if vertex != source and vertex != node and (mask >> vertex) & 1:
                            through[vertex][source][node] += 1
            for neighbor in range(node_count):
                weight = adjacency[node][neighbor]
                if weight is not None and not (mask >> neighbor) & 1:
                    walk(neighbor, distance + weight, mask | (1 << neighbor))

        walk(source, 0, 1 << source)

    answers = []
    for vertex in range(node_count):
        value = 0.0
        for source in range(node_count):
            if source == vertex:
                continue
            for target in range(node_count):
                if target == vertex or target == source:
                    continue
                if counts[source][target] > 0:
                    value += through[vertex][source][target] / counts[source][target]
        answers.append(f"{value:.3f}")
    return answers


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        node_count = tokens[cursor]
        edge_count = tokens[cursor + 1]
        cursor += 2
        adjacency = [[None] * node_count for _ in range(node_count)]
        for _ in range(edge_count):
            first_node = tokens[cursor] - 1
            second_node = tokens[cursor + 1] - 1
            weight = tokens[cursor + 2]
            cursor += 3
            adjacency[first_node][second_node] = weight
            adjacency[second_node][first_node] = weight
        answers.extend(brute_importance(node_count, adjacency))
    return "\n".join(answers) + "\n"


SAMPLE = "1\n4 4\n1 2 1\n2 3 1\n3 4 1\n4 1 1\n"
SAMPLE_OUT = "1.000\n1.000\n1.000\n1.000\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 3\n1 2 1\n2 3 1\n1 3 1\n") == "0.000\n0.000\n0.000\n"
assert oracle("1\n2 1\n1 2 1\n") == "0.000\n0.000\n"
assert oracle("1\n4 5\n1 2 1\n2 3 1\n3 4 1\n4 1 1\n1 3 2\n") == "1.000\n0.667\n1.000\n0.667\n"


def build_graph(node_count, extra_edges, rng):
    edges = [(index, index + 1, rng.randint(1, 5)) for index in range(node_count - 1)]
    possible = [(first, second) for first in range(node_count) for second in range(first + 2, node_count)]
    rng.shuffle(possible)
    for first, second in possible[:extra_edges]:
        edges.append((first, second, rng.randint(1, 8)))
    return edges


def write(name, graphs):
    pieces = [str(len(graphs))]
    for node_count, edges in graphs:
        pieces.append(f"{node_count} {len(edges)}")
        for first, second, weight in edges:
            pieces.append(f"{first + 1} {second + 1} {weight}")
    text = "\n".join(pieces) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        (2, [(0, 1, 1)]),
        (3, [(0, 1, 1), (1, 2, 1), (0, 2, 1)]),
        (4, [(0, 1, 2), (1, 2, 2), (2, 3, 2), (3, 0, 2)]),
    ])
    write("3_wide", [(7, build_graph(7, 10, rng))])
    random_graphs = []
    for _ in range(12):
        node_count = rng.randint(4, 7)
        random_graphs.append((node_count, build_graph(node_count, rng.randint(0, 8), rng)))
    write("4_random", random_graphs)
    io_graphs = [(7, build_graph(7, 10, rng)) for _ in range(60)]
    write("5_io", io_graphs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, [(0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 0, 1)])])
build()
