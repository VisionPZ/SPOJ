#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """2
2 2
1 2
2 1
3 3
2 1 3
3 1 2
"""
SAMPLE_OUT = """3
10
"""


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        size = int(tokens[cursor])
        limit = int(tokens[cursor + 1])
        cursor += 2
        first_perm = [int(value) - 1 for value in tokens[cursor:cursor + size]]
        cursor += size
        second_perm = [int(value) - 1 for value in tokens[cursor:cursor + size]]
        cursor += size
        generators = (tuple(first_perm), tuple(second_perm))
        configs = list(itertools.product(range(limit), repeat=size))
        positions = {config: index for index, config in enumerate(configs)}
        parent = list(range(len(configs)))

        def find(node):
            while parent[node] != node:
                parent[node] = parent[parent[node]]
                node = parent[node]
            return node

        def union(left, right):
            left_root = find(left)
            right_root = find(right)
            if left_root != right_root:
                parent[right_root] = left_root

        for config, config_index in positions.items():
            for perm in generators:
                moved = tuple(config[perm[position]] for position in range(size))
                union(config_index, positions[moved])
        answers.append(str(len({find(index) for index in range(len(configs))})))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 5\n1\n1\n") == "5\n"
assert oracle("1\n2 1\n1 2\n1 2\n") == "1\n"
assert oracle("1\n3 2\n2 1 3\n3 1 2\n") == "4\n"
assert oracle("1\n2 3\n2 1\n1 2\n") == "6\n"


def render(cases):
    lines = [str(len(cases))]
    for size, limit, first_perm, second_perm in cases:
        lines.append(f"{size} {limit}")
        lines.append(" ".join(str(value) for value in first_perm))
        lines.append(" ".join(str(value) for value in second_perm))
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 1, [1], [1]),
        (1, 10, [1], [1]),
        (2, 1, [1, 2], [2, 1]),
        (2, 5, [1, 2], [1, 2]),
        (3, 1, [2, 1, 3], [3, 1, 2]),
    ])
    write("3_wide", [
        (8, 2, [2, 3, 4, 5, 6, 7, 8, 1], [2, 1, 3, 4, 5, 6, 7, 8]),
        (8, 3, [8, 7, 6, 5, 4, 3, 2, 1], [2, 1, 4, 3, 6, 5, 8, 7]),
    ])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(8):
        size = rng.randint(2, 6)
        limit = rng.randint(1, 3)
        first_perm = list(range(1, size + 1))
        second_perm = list(range(1, size + 1))
        rng.shuffle(first_perm)
        rng.shuffle(second_perm)
        random_cases.append((size, limit, first_perm, second_perm))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        size = 8
        first_perm = list(range(1, size + 1))
        second_perm = list(range(1, size + 1))
        rng.shuffle(first_perm)
        rng.shuffle(second_perm)
        io_cases.append((size, 3, first_perm, second_perm))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
