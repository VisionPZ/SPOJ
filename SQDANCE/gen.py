#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        prime_count = int(tokens[cursor])
        cursor += 1
        relation_count = int(tokens[cursor])
        cursor += 1
        adjacency = [[] for _ in range(prime_count + 1)]
        for _ in range(relation_count):
            left = int(tokens[cursor])
            cursor += 1
            right = int(tokens[cursor])
            cursor += 1
            adjacency[left].append(right)
            adjacency[right].append(left)
        visited = bytearray(prime_count + 1)
        components = 0
        for start in range(1, prime_count + 1):
            if visited[start]:
                continue
            components += 1
            visited[start] = 1
            stack = [start]
            while stack:
                node = stack.pop()
                for neighbor in adjacency[node]:
                    if not visited[neighbor]:
                        visited[neighbor] = 1
                        stack.append(neighbor)
        answers.append(str(relation_count - prime_count + components))
    return "\n".join(answers) + "\n"


def write(name, cases):
    parts = [str(len(cases))]
    for prime_count, relations in cases:
        parts.append(f"{prime_count} {len(relations)}")
        for left, right in relations:
            parts.append(f"{left} {right}")
    input_text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [
    (6, [(1, 2), (3, 5), (2, 4), (1, 4), (3, 5), (1, 6), (4, 6)]),
    (2, [(1, 2), (1, 2), (1, 2)]),
]

assert oracle("1\n6 7\n1 2\n3 5\n2 4\n1 4\n3 5\n1 6\n4 6\n") == "3\n"
assert oracle("1\n2 3\n1 2\n1 2\n1 2\n") == "2\n"
assert oracle("1\n5 4\n1 2\n2 3\n3 4\n4 5\n") == "0\n"
assert oracle("1\n5 5\n1 2\n2 3\n3 4\n4 5\n1 5\n") == "1\n"
assert oracle("1\n1 1\n1 1\n") == "1\n"


def build():
    edges = [
        (1, [(1, 1)]),
        (2, [(1, 2)]),
        (5, [(1, 2), (2, 3), (3, 4), (4, 5)]),
        (5, [(1, 2), (2, 3), (3, 4), (4, 5), (1, 5), (2, 4)]),
        (100000, [(1, 100000)]),
        (100000, [(index, index + 1) for index in range(1, 100000)] + [(1, 100000)]),
    ]
    write("2_edges", edges)

    wide = [
        (100000, [(index, index + 1) for index in range(1, 100000)] + [(1, 100000)] * 2),
        (100000, [(1, index) for index in range(2, 100001)] + [(99999, 100000)] * 2),
    ]
    write("3_wide", wide)

    random.seed(2026)
    random_cases = []
    for _ in range(30):
        prime_count = random.randint(1, 1000)
        relation_count = random.randint(1, 1000)
        relations = [
            (random.randint(1, prime_count), random.randint(1, prime_count))
            for _ in range(relation_count)
        ]
        random_cases.append((prime_count, relations))
    write("4_random", random_cases)

    io_cases = []
    for _ in range(30):
        relations = [
            (random.randint(1, 100000), random.randint(1, 100000))
            for _ in range(100000)
        ]
        io_cases.append((100000, relations))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
