#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_total = tokens[cursor]
    cursor += 1
    result = []
    for case_index in range(case_total):
        student_count = tokens[cursor]
        relation_count = tokens[cursor + 1]
        cursor += 2
        money = tokens[cursor:cursor + student_count]
        cursor += student_count
        adjacency = [[] for _ in range(student_count)]
        for _ in range(relation_count):
            first = tokens[cursor] - 1
            second = tokens[cursor + 1] - 1
            cursor += 2
            adjacency[first].append(second)
            adjacency[second].append(first)
        seen = [False] * student_count
        budgets = []
        for start in range(student_count):
            if seen[start]:
                continue
            stack = [start]
            seen[start] = True
            total = 0
            while stack:
                node = stack.pop()
                total += money[node]
                for neighbour in adjacency[node]:
                    if not seen[neighbour]:
                        seen[neighbour] = True
                        stack.append(neighbour)
            budgets.append(total)
        budgets.sort()
        result.append(f"Case {case_index + 1}: {len(budgets)}")
        result.append(" ".join(str(value) for value in budgets))
    return "\n".join(result) + "\n"


SAMPLE = """1
5 3
5 7 4 6 8
1 2
1 3
4 5
"""
SAMPLE_OUT = """Case 1: 2
14 16
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 0\n7\n") == "Case 1: 1\n7\n"
assert oracle("1\n3 0\n5 5 5\n") == "Case 1: 3\n5 5 5\n"
assert oracle("1\n2 1\n1 2\n1 2\n") == "Case 1: 1\n3\n"
assert sum(5 + 7 + 4 + 6 + 8 for _ in range(1)) == 30


def write(name, cases):
    parts = [str(len(cases))]
    for student_count, relation_count, money, edges in cases:
        parts.append(f"{student_count} {relation_count}")
        parts.append(" ".join(str(value) for value in money))
        for first, second in edges:
            parts.append(f"{first} {second}")
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, student_count, edge_probability):
    money = [rng.randint(1, 100) for _ in range(student_count)]
    edges = []
    for first in range(1, student_count + 1):
        for second in range(first + 1, student_count + 1):
            if rng.random() < edge_probability:
                edges.append((first, second))
    return (student_count, len(edges), money, edges)


def build():
    write("2_edges", [
        (1, 0, [9], []),
        (4, 3, [1, 2, 3, 4], [(1, 2), (2, 3), (3, 4)]),
        (3, 0, [100, 1, 50], []),
    ])
    write("3_wide", [(1000, 0, [100] * 1000, [])])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng, 60, 0.05) for _ in range(5)])
    write("5_io", [(1000, 0, [(index % 100) + 1 for index in range(1000)], [])
                   for _ in range(50)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5, 3, [5, 7, 4, 6, 8], [(1, 2), (1, 3), (4, 5)])])
build()
