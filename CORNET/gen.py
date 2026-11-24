#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        enterprise_count = int(tokens[cursor]); cursor += 1
        parent = list(range(enterprise_count + 1))
        distance = [0] * (enterprise_count + 1)
        while True:
            command = tokens[cursor]; cursor += 1
            if command == 'O':
                break
            if command == 'E':
                node = int(tokens[cursor]); cursor += 1
                total = 0
                current = node
                while parent[current] != current:
                    total += distance[current]
                    current = parent[current]
                answers.append(str(total))
            else:
                center = int(tokens[cursor]); cursor += 1
                linked = int(tokens[cursor]); cursor += 1
                parent[center] = linked
                distance[center] = abs(center - linked) % 1000
    return "\n".join(answers) + "\n"


SAMPLE_IN = (
    "1\n4\nE 3\nI 3 1\nE 3\nI 1 2\nE 3\nI 2 4\nE 3\nO\n"
)
SAMPLE_OUT = "0\n2\n3\n5\n"

assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n5\nE 1\nE 5\nO\n") == "0\n0\n"
assert oracle("1\n2000\nI 1 1500\nE 1\nO\n") == "499\n"
assert oracle("1\n2000\nI 1 2\nI 2 3\nE 1\nE 2\nO\n") == "2\n1\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build_edges():
    parts = []
    parts.append("6\n")
    parts.append("5\nE 1\nE 5\nO\n")
    parts.append("5\nI 1 5\nE 1\nE 5\nO\n")
    parts.append("2000\nI 1 1500\nE 1\nO\n")
    parts.append("2000\nI 1 2\nI 2 3\nE 1\nE 2\nO\n")
    parts.append("5\nE 3\nI 3 1\nE 3\nI 1 2\nE 3\nO\n")
    parts.append("5\nE 1\nE 2\nE 3\nE 4\nE 5\nO\n")
    return "".join(parts)


def build_wide():
    parts = ["1\n", "20000\n"]
    for node in range(1, 20000):
        parts.append(f"I {node} {node + 1}\n")
    parts.append("E 1\nE 10000\nE 19999\nO\n")
    return "".join(parts)


def find_root(parent, node):
    while parent[node] != node:
        node = parent[node]
    return node


def build_random():
    random.seed(2026)
    parts = ["3\n"]
    for _ in range(3):
        enterprise_count = random.randint(5, 2000)
        parts.append(f"{enterprise_count}\n")
        parent = list(range(enterprise_count + 1))
        command_count = 0
        while command_count < 20000:
            if random.random() < 0.7:
                node = random.randint(1, enterprise_count)
                parts.append(f"E {node}\n")
            else:
                center = random.randint(1, enterprise_count)
                center = find_root(parent, center)
                linked = random.randint(1, enterprise_count)
                if find_root(parent, linked) == center:
                    continue
                parts.append(f"I {center} {linked}\n")
                parent[center] = linked
            command_count += 1
        parts.append("O\n")
    return "".join(parts)


def build_io():
    parts = ["5\n"]
    leaf_count = 19999
    query_count = 200000 - leaf_count - 1
    for _ in range(5):
        parts.append("20000\n")
        for node in range(2, 20001):
            parts.append(f"I {node} 1\n")
        for query_index in range(query_count):
            parts.append(f"E {2 + (query_index % leaf_count)}\n")
        parts.append("O\n")
    return "".join(parts)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_IN)
write("2_edges", build_edges())
write("3_wide", build_wide())
write("4_random", build_random())
write("5_io", build_io())
