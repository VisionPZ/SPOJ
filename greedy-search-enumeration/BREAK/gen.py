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
        node_count = int(tokens[cursor])
        edge_count = int(tokens[cursor + 1])
        cursor += 2
        trusted_by = [[] for _ in range(node_count)]
        for _ in range(edge_count):
            trusting = int(tokens[cursor]) - 1
            trusted = int(tokens[cursor + 1]) - 1
            cursor += 2
            trusted_by[trusted].append(trusting)
        importance = []
        for start in range(node_count):
            seen = [False] * node_count
            seen[start] = True
            stack = [start]
            while stack:
                current = stack.pop()
                for nxt in trusted_by[current]:
                    if not seen[nxt]:
                        seen[nxt] = True
                        stack.append(nxt)
            importance.append(sum(seen))
        best = max(importance)
        answers.append(" ".join(str(index + 1) for index, value in enumerate(importance) if value == best))
    return "\n".join(answers) + "\n"


SAMPLE = """2

5 4
3 1
3 2
4 3
5 3

6 5
1 2
2 3
3 1
1 4
5 6
"""
SAMPLE_OUT = """1 2
4
"""
EXTRA = """1

6 6
1 2
3 2
3 4
2 4
2 5
5 6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(EXTRA) == "6\n"
assert oracle("1\n3 1\n1 2\n") == "2\n"
assert oracle("1\n3 3\n1 2\n2 3\n3 1\n") == "1 2 3\n"


def write(name, cases):
    parts = [str(len(cases))]
    for node_count, edges in cases:
        parts.append("")
        parts.append(f"{node_count} {len(edges)}")
        parts.extend(f"{first} {second}" for first, second in edges)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(3, [(1, 2)]), (4, [(1, 1), (2, 3), (3, 2)]), (2, [(2, 1)])])
    wide_edges = [(index, index + 1) for index in range(1, 100)]
    wide_edges.extend((index + 1, index) for index in range(1, 100))
    write("3_wide", [(100, wide_edges)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(3):
        edges = [(rng.randint(1, 60), rng.randint(1, 60)) for _ in range(300)]
        random_cases.append((60, edges))
    write("4_random", random_cases)
    cycle = [(index, index + 1) for index in range(1, 1000)] + [(1000, 1)]
    write("5_io", [(1000, cycle)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
