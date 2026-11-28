#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(vertex_count, edges):
    neighbor_bits = [0] * vertex_count
    for first, second in edges:
        neighbor_bits[first] |= 1 << second
        neighbor_bits[second] |= 1 << first
    remaining = (1 << vertex_count) - 1
    while remaining:
        scan_bits = remaining
        simplicial_vertex = None
        while scan_bits:
            low_bit = scan_bits & -scan_bits
            vertex = low_bit.bit_length() - 1
            scan_bits -= low_bit
            neighborhood = neighbor_bits[vertex] & remaining
            check_bits = neighborhood
            clique = True
            while check_bits:
                current_bit = check_bits & -check_bits
                other = current_bit.bit_length() - 1
                check_bits -= current_bit
                if (neighborhood & ~neighbor_bits[other]) & ~current_bit:
                    clique = False
                    break
            if clique:
                simplicial_vertex = vertex
                break
        if simplicial_vertex is None:
            return False
        remaining &= ~(1 << simplicial_vertex)
    return True


def solve_text(text):
    numbers = [int(value) for value in re.findall(r"\d+", text)]
    cursor = 0
    count = numbers[cursor]; cursor += 1
    answers = []
    for _ in range(count):
        vertex_count = numbers[cursor]; cursor += 1
        edge_count = numbers[cursor]; cursor += 1
        edges = []
        for _ in range(edge_count):
            first = numbers[cursor]; cursor += 1
            second = numbers[cursor]; cursor += 1
            edges.append((first, second))
        answers.append("YES" if oracle(vertex_count, edges) else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = """2
n=6,m=4
{0,1} {2,3} {3,4} {3,5} 
n=6,m=7
{0,3} {1,2} {1,3} {2,4} {2,5} {3,4} {3,5} 
"""
SAMPLE_OUT = "YES\nNO\n"
assert solve_text(SAMPLE) == SAMPLE_OUT
assert oracle(4, [(0, 1), (1, 2), (2, 3), (3, 0)]) is False
assert oracle(3, [(0, 1), (1, 2), (2, 0)]) is True
assert oracle(6, [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (3, 5)]) is False
assert oracle(5, []) is True


def write(name, graphs):
    lines = [str(len(graphs))]
    for vertex_count, edges in graphs:
        lines.append(f"n={vertex_count},m={len(edges)}")
        edge_text = " ".join(f"{{{first},{second}}}" for first, second in edges)
        lines.append(edge_text + " ")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(solve_text(text))


def random_graph(vertex_count, rng, probability):
    edges = []
    for first in range(vertex_count):
        for second in range(first + 1, vertex_count):
            if rng.random() < probability:
                edges.append((first, second))
    return vertex_count, edges


def build():
    write("2_edges", [
        (1, []),
        (3, [(0, 1)]),
        (3, [(0, 1), (1, 2), (2, 0)]),
        (4, [(0, 1), (1, 2), (2, 3), (3, 0)]),
        (4, [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2), (1, 3)]),
        (6, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (0, 2), (0, 4), (2, 4)]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_graph(300, rng, 0.06) for _ in range(20)])
    write("4_random", [random_graph(rng.randint(2, 40), rng, rng.choice([0.05, 0.2, 0.5, 0.8]))
                       for _ in range(60)])
    write("5_io", [random_graph(30, rng, 0.12) for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
