#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def cut_size(matrix, side):
    total = 0
    size = len(matrix)
    for first in range(size):
        for second in range(first + 1, size):
            if (first in side) != (second in side):
                total += matrix[first][second]
    return total


def brute_cut(matrix):
    size = len(matrix)
    best = size * size
    for mask in range(0, (1 << (size - 1)) - 1):
        side = {0}
        for index in range(1, size):
            if mask & (1 << (index - 1)):
                side.add(index)
        best = min(best, cut_size(matrix, side))
    return best


def flow_cut(matrix, source, sink):
    size = len(matrix)
    residual = [row[:] for row in matrix]
    flow = 0
    while True:
        parent = [-1] * size
        parent[source] = source
        queue = [source]
        for node in queue:
            for neighbor in range(size):
                if parent[neighbor] == -1 and residual[node][neighbor] > 0:
                    parent[neighbor] = node
                    queue.append(neighbor)
        if parent[sink] == -1:
            break
        bottleneck = size * size
        walker = sink
        while walker != source:
            previous = parent[walker]
            bottleneck = min(bottleneck, residual[previous][walker])
            walker = previous
        walker = sink
        while walker != source:
            previous = parent[walker]
            residual[previous][walker] -= bottleneck
            residual[walker][previous] += bottleneck
            walker = previous
        flow += bottleneck
    return flow


def oracle(text):
    tokens = [int(value) for value in text.split()]
    size = tokens[0]
    matrix = [tokens[1 + index * size:1 + (index + 1) * size] for index in range(size)]
    return str(2 * min(flow_cut(matrix, source, 0) for source in range(1, size))) + "\n"


SAMPLE_A = """2
0 1
1 0
"""
SAMPLE_B = """5
0 1 0 0 1
1 0 0 1 0
0 0 0 1 0
0 1 1 0 0
1 0 0 0 0
"""
SAMPLE_C = """10
0 0 0 0 0 0 1 1 0 1
0 0 0 0 0 1 0 0 1 0
0 0 0 0 0 0 0 1 0 0
0 0 0 0 0 0 1 0 0 0
0 0 0 0 0 0 0 0 0 1
0 1 0 0 0 0 0 0 0 0
1 0 0 1 0 0 0 0 0 0
1 0 1 0 0 0 0 0 0 0
0 1 0 0 0 0 0 0 0 1
1 0 0 0 1 0 0 0 1 0
"""
SAMPLE_D = """30
0 0 0 0 0 1 0 0 1 0 0 0 0 1 1 0 1 0 0 0 0 1 0 0 1 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 1 0
0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0
0 0 0 0 0 1 0 0 1 0 0 1 0 0 0 0 1 0 0 0 0 0 0 1 0 0 1 0 1 0
0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 1 0 0 0 0
1 0 0 1 1 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0
1 0 0 1 0 0 0 0 0 0 1 1 0 0 1 1 1 0 1 0 0 0 0 1 0 0 0 0 0 0
0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0
0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0
0 0 0 1 0 1 0 0 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1
0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0
1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 1 0
1 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 1 1 0
0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0
1 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0
0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
0 0 0 0 1 0 0 0 1 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 1
0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 1 0 0 0 0 0 1 0 0 0 1 0 1 0
0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0
1 0 1 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0
0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1 0
0 0 0 1 0 0 0 1 1 0 0 0 0 1 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0
1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1
0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0
0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1
0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0
0 1 0 1 0 0 0 0 0 1 0 0 0 1 1 0 0 0 1 1 1 0 1 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 1 0 1 0 0 0
"""
assert oracle(SAMPLE_A) == "2\n"
assert oracle(SAMPLE_B) == "2\n"
assert oracle(SAMPLE_C) == "2\n"
assert oracle(SAMPLE_D) == "4\n"
assert brute_cut([[0, 1], [1, 0]]) == 1
assert brute_cut([[0, 1, 0], [1, 0, 1], [0, 1, 0]]) == 1


def random_graph(size, rng):
    matrix = [[0] * size for _ in range(size)]
    for vertex in range(1, size):
        parent = rng.randrange(vertex)
        matrix[vertex][parent] = matrix[parent][vertex] = 1
    for first in range(size):
        for second in range(first + 1, size):
            if rng.random() < 0.1:
                matrix[first][second] = matrix[second][first] = 1
    return matrix


def write(name, matrix):
    size = len(matrix)
    lines = [str(size)]
    lines.extend(" ".join(str(value) for value in row) for row in matrix)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [[0, 1, 1], [1, 0, 0], [1, 0, 0]])
    write("3_wide", random_graph(12, rng))
    write("4_random", random_graph(18, rng))
    write("5_io", random_graph(26, rng))
    big = random_graph(900, rng)
    big_lines = ["900"]
    big_lines.extend(" ".join(str(value) for value in row) for row in big)
    Path("/tmp/ADABANKET_big.txt").write_text("\n".join(big_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_A)
(ROOT / "out" / "1_sample.out").write_text("2\n")
build()
