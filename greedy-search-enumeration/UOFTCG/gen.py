#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        students = tokens[position]
        edges = tokens[position + 1]
        position += 2
        pairs = []
        for _ in range(edges):
            pairs.append((tokens[position], tokens[position + 1]))
            position += 2
        best_used = 0
        for mask in range(1 << edges):
            degree = [0] * (students + 1)
            used = 0
            for index, (left, right) in enumerate(pairs):
                if mask & (1 << index):
                    degree[left] += 1
                    degree[right] += 1
                    used += 1
            if all(count <= 2 for count in degree[1:]):
                best_used = max(best_used, used)
        path_count = students - best_used
        answers.append(students + path_count - 1)
    return "".join(str(answer) + "\n" for answer in answers)


SAMPLE = """1
6 5
1 2
1 3
1 4
4 5
4 6
"""
SAMPLE_OUT = """7
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 0\n") == "5\n"
assert oracle("1\n4 3\n1 2\n2 3\n3 4\n") == "4\n"
assert oracle("1\n5 4\n1 2\n1 3\n1 4\n1 5\n") == "7\n"
assert oracle("2\n1 0\n2 1\n1 2\n") == "1\n2\n"


def write(name, cases):
    lines = [str(len(cases))]
    for students, edges in cases:
        lines.append(f"{students} {len(edges)}")
        for left, right in edges:
            lines.append(f"{left} {right}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def tree(students, rng):
    return [(child, rng.randint(1, child - 1)) for child in range(2, students + 1)]


def build():
    write("2_edges", [
        (1, []),
        (2, []),
        (2, [(1, 2)]),
        (5, [(1, 2), (1, 3), (1, 4), (1, 5)]),
        (6, [(1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [(11, tree(11, rng))])
    random_cases = []
    for _ in range(5):
        students = rng.randint(2, 11)
        edges = tree(students, rng)
        rng.shuffle(edges)
        random_cases.append((students, edges))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        students = rng.randint(1, 9)
        edges = tree(students, rng) if students > 1 else []
        io_cases.append((students, edges))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(6, [(1, 2), (1, 3), (1, 4), (4, 5), (4, 6)])])
build()
