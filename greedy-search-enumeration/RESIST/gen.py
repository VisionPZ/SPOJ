#!/usr/bin/env python3
import itertools
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def build_system(node_count, edges):
    size = node_count - 1
    matrix = [[Fraction(0) for _ in range(size)] for _ in range(size)]
    for first_node, second_node, resistance in edges:
        first_node -= 1
        second_node -= 1
        if first_node == second_node:
            continue
        conductance = Fraction(1, resistance)
        if first_node != size:
            matrix[first_node][first_node] += conductance
        if second_node != size:
            matrix[second_node][second_node] += conductance
        if first_node != size and second_node != size:
            matrix[first_node][second_node] -= conductance
            matrix[second_node][first_node] -= conductance
    return matrix


def determinant(matrix):
    size = len(matrix)
    total = Fraction(0)
    for permutation in itertools.permutations(range(size)):
        sign = 1
        positions = list(permutation)
        for first in range(size):
            for second in range(first + 1, size):
                if positions[first] > positions[second]:
                    sign = -sign
        term = Fraction(sign)
        for row_index, column_index in enumerate(permutation):
            term *= matrix[row_index][column_index]
            if term == 0:
                break
        total += term
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    lines = []
    while cursor < len(tokens):
        node_count = tokens[cursor]
        cursor += 1
        edge_count = tokens[cursor]
        cursor += 1
        edges = []
        for _ in range(edge_count):
            edges.append((tokens[cursor], tokens[cursor + 1], tokens[cursor + 2]))
            cursor += 3
        matrix = build_system(node_count, edges)
        for row_index in range(node_count - 1):
            if all(matrix[row_index][column_index] == 0
                   for column_index in range(node_count - 1)):
                matrix[row_index][row_index] = Fraction(1)
        denominator = determinant(matrix)
        replaced = [row[:] for row in matrix]
        for row_index in range(node_count - 1):
            replaced[row_index][0] = Fraction(1 if row_index == 0 else 0)
        numerator = determinant(replaced)
        resistance = numerator / denominator
        scaled = int(float(resistance) * 100 + 0.5000001)
        lines.append(f"{scaled // 100}.{scaled % 100:02d}")
    return "\n".join(lines) + "\n"


SAMPLE = """4 5
1 2 15
2 4 5
1 3 10
3 4 10
2 3 1
"""
SAMPLE_OUT = """9.40
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1\n1 2 5\n") == "5.00\n"
assert oracle("3 3\n1 2 1\n2 3 1\n1 3 1\n") == "0.67\n"
assert oracle("4 3\n1 2 3\n2 3 4\n3 4 7\n") == "14.00\n"
assert oracle("3 3\n1 2 4\n2 3 6\n1 3 12\n") == "5.45\n"


def encode(cases):
    blocks = []
    for node_count, edges in cases:
        lines = [f"{node_count} {len(edges)}"]
        for edge in edges:
            lines.append(" ".join(str(value) for value in edge))
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks) + "\n"


def write(name, cases):
    input_text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def connected(node_count, edges):
    neighbours = [[] for _ in range(node_count + 1)]
    for first_node, second_node, _ in edges:
        neighbours[first_node].append(second_node)
        neighbours[second_node].append(first_node)
    reached = {1}
    pending = [1]
    while pending:
        current = pending.pop()
        for neighbour in neighbours[current]:
            if neighbour not in reached:
                reached.add(neighbour)
                pending.append(neighbour)
    return len(reached) == node_count


def build():
    write("2_edges", [
        (2, [(1, 2, 7)]),
        (3, [(1, 2, 4), (2, 3, 9)]),
        (4, [(1, 2, 1), (1, 3, 1), (2, 4, 1), (3, 4, 1)]),
        (5, [(1, 2, 5), (2, 5, 6)]),
        (3, [(1, 1, 10), (1, 3, 2), (2, 2, 4)]),
    ])
    rng = random.Random(20261126)
    wide_edges = []
    for first_node in range(1, 6):
        for second_node in range(first_node + 1, 7):
            wide_edges.append((first_node, second_node, rng.randint(1, 100)))
    for _ in range(6):
        wide_edges.append((rng.randint(1, 7), rng.randint(1, 7), rng.randint(1, 100)))
    write("3_wide", [(7, wide_edges)])
    random_cases = []
    for _ in range(12):
        node_count = rng.randint(3, 7)
        edges = [(rng.randint(1, node_count), rng.randint(1, node_count),
                  rng.randint(1, 100)) for _ in range(rng.randint(2, 12))]
        random_cases.append((node_count, edges))
    write("4_random", [case for case in random_cases if connected(*case)])
    io_cases = []
    while len(io_cases) < 60:
        node_count = rng.randint(3, 7)
        edges = [(rng.randint(1, node_count), rng.randint(1, node_count),
                  rng.randint(1, 100)) for _ in range(rng.randint(2, 10))]
        if connected(node_count, edges):
            io_cases.append((node_count, edges))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, [(1, 2, 15), (2, 4, 5), (1, 3, 10), (3, 4, 10), (2, 3, 1)])])
build()
