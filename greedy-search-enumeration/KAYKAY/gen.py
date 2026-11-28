#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def connected_subsets(vertex_count, values, edges, target_size):
    adjacency = [[] for _ in range(vertex_count)]
    for left, right in edges:
        adjacency[left].append(right)
        adjacency[right].append(left)
    result = []
    for mask in range(1, 1 << vertex_count):
        if mask.bit_count() != target_size:
            continue
        start = (mask & -mask).bit_length() - 1
        reached = 1 << start
        stack = [start]
        while stack:
            current = stack.pop()
            for neighbor in adjacency[current]:
                if mask >> neighbor & 1 and not (reached >> neighbor & 1):
                    reached |= 1 << neighbor
                    stack.append(neighbor)
        if reached != mask:
            continue
        total = sum(values[index] for index in range(vertex_count) if mask >> index & 1)
        result.append((mask, total))
    return result


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        vertex_count = tokens[cursor]
        first_size = tokens[cursor + 1]
        second_size = tokens[cursor + 2]
        cursor += 3
        values = tokens[cursor:cursor + vertex_count]
        cursor += vertex_count
        edges = []
        for _ in range(vertex_count - 1):
            edges.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        first_subsets = connected_subsets(vertex_count, values, edges, first_size)
        second_subsets = connected_subsets(vertex_count, values, edges, second_size)
        best = None
        for first_mask, first_total in first_subsets:
            for second_mask, second_total in second_subsets:
                if first_mask & second_mask:
                    continue
                candidate = first_total - second_total
                if best is None or candidate > best:
                    best = candidate
        answers.append(str(best if best is not None else -1))
    return "\n".join(answers) + "\n"


SAMPLE = ("2\n7 3 3\n0 1 -1 2 3 -2 -3\n0 1\n0 2\n1 3\n1 4\n2 5\n2 6\n"
          "3 2 2\n1 2 3\n0 1\n0 2\n")
SAMPLE_OUT = "12\n-1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1 1\n5 -3\n0 1\n") == "8\n"
assert oracle("1\n3 1 1\n-1 -2 -3\n0 1\n1 2\n") == "2\n"
assert oracle("1\n4 2 1\n1 1 1 1\n0 1\n1 2\n2 3\n") == "1\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for vertex_count, first_size, second_size, values, edges in cases:
        text += f"{vertex_count} {first_size} {second_size}\n"
        text += " ".join(str(value) for value in values) + "\n"
        for left, right in edges:
            text += f"{left} {right}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, vertex_count):
    first_size = rng.randint(1, vertex_count)
    second_size = rng.randint(1, vertex_count)
    values = [rng.randint(-20, 20) for _ in range(vertex_count)]
    edges = [(parent, child) for child in range(1, vertex_count)
             for parent in [rng.randint(0, child - 1)]]
    return vertex_count, first_size, second_size, values, edges


def build():
    write("2_edges", [(2, 1, 1, [5, -3], [(0, 1)]),
                      (3, 1, 1, [-1, -2, -3], [(0, 1), (1, 2)]),
                      (4, 2, 1, [1, 1, 1, 1], [(0, 1), (1, 2), (2, 3)]),
                      (5, 2, 2, [4, -5, 6, -7, 8], [(0, 1), (0, 2), (1, 3), (2, 4)])])
    write("3_wide", [(8, 4, 3, [100, -9, 8, -7, 6, -5, 4, -3],
                      [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6), (5, 7)]),
                     (8, 2, 2, [-100, 9, -8, 7, -6, 5, -4, 3],
                      [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6), (5, 7)])])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng, rng.randint(2, 11)) for _ in range(10)])
    write("5_io", [random_case(rng, rng.randint(8, 12)) for _ in range(14)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(7, 3, 3, [0, 1, -1, 2, 3, -2, -3],
                    [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)]),
                   (3, 2, 2, [1, 2, 3], [(0, 1), (0, 2)])])
build()
