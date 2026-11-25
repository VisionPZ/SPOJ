#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    node_count = tokens[cursor]
    cursor += 1
    adjacency = [[] for _ in range(node_count + 1)]
    for _ in range(node_count - 1):
        first_node = tokens[cursor]
        second_node = tokens[cursor + 1]
        cursor += 2
        adjacency[first_node].append(second_node)
        adjacency[second_node].append(first_node)
    instruction_count = tokens[cursor]
    cursor += 1
    white = set()
    answers = []
    for _ in range(instruction_count):
        kind = tokens[cursor]
        cursor += 1
        node = tokens[cursor]
        cursor += 1
        if kind == 0:
            if node in white:
                white.remove(node)
            else:
                white.add(node)
            continue
        if not white:
            answers.append("-1")
            continue
        distance = [-1] * (node_count + 1)
        distance[node] = 0
        queue = deque([node])
        answer = -1
        while queue:
            current = queue.popleft()
            if current in white:
                answer = distance[current]
                break
            for neighbor in adjacency[current]:
                if distance[neighbor] == -1:
                    distance[neighbor] = distance[current] + 1
                    queue.append(neighbor)
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


SAMPLE_IN = """10
1 2
1 3
2 4
1 5
1 6
4 7
7 8
5 9
1 10
10
0 6
0 6
0 6
1 3
0 1
0 1
1 3
1 10
1 4
1 6
"""
SAMPLE_OUT = """2
2
2
3
0
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n2\n0 1\n1 1\n") == "0\n"
assert oracle("2\n1 2\n3\n1 1\n0 2\n1 1\n") == "-1\n1\n"
assert oracle("3\n1 2\n2 3\n4\n0 3\n1 1\n0 2\n1 1\n") == "2\n1\n"


def write(name, node_count, edges, instructions):
    lines = [str(node_count)]
    lines.extend(f"{first} {second}" for first, second in edges)
    lines.append(str(len(instructions)))
    lines.extend(f"{kind} {node}" for kind, node in instructions)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_tree(rng, node_count):
    return [(child, rng.randint(1, child - 1)) for child in range(2, node_count + 1)]


def random_instructions(rng, count, node_count):
    instructions = []
    for _ in range(count):
        if rng.random() < 0.45:
            instructions.append((0, rng.randint(1, node_count)))
        else:
            instructions.append((1, rng.randint(1, node_count)))
    return instructions


def build():
    rng = random.Random(20261126)
    write("2_edges", 1, [], [(1, 1), (0, 1), (1, 1)])
    write("3_wide", 20000, random_tree(rng, 20000),
          random_instructions(rng, 200, 20000))
    write("4_random", 3000, random_tree(rng, 3000),
          random_instructions(rng, 800, 3000))
    write("5_io", 10000, random_tree(rng, 10000),
          random_instructions(rng, 1500, 10000))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
