#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    position = 0
    test_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(test_count):
        student_count = int(tokens[position])
        relation_count = int(tokens[position + 1])
        target = int(tokens[position + 2])
        position += 3
        forward = [set() for _ in range(student_count + 1)]
        backward = [set() for _ in range(student_count + 1)]
        for _ in range(relation_count):
            lower = int(tokens[position])
            higher = int(tokens[position + 1])
            position += 2
            forward[lower].add(higher)
            backward[higher].add(lower)
        color = [0] * (student_count + 1)
        cyclic = False
        for start in range(1, student_count + 1):
            if color[start]:
                continue
            stack = [(start, iter(forward[start]))]
            color[start] = 1
            while stack:
                node, neighbours = stack[-1]
                next_node = next(neighbours, None)
                if next_node is None:
                    color[node] = 2
                    stack.pop()
                elif color[next_node] == 1:
                    cyclic = True
                elif color[next_node] == 0:
                    color[next_node] = 1
                    stack.append((next_node, iter(forward[next_node])))
        if cyclic:
            answers.append("-1")
            continue

        def reachable(graph):
            seen = {target}
            stack = [target]
            while stack:
                node = stack.pop()
                for neighbour in graph[node]:
                    if neighbour not in seen:
                        seen.add(neighbour)
                        stack.append(neighbour)
            return seen

        ancestors = reachable(backward)
        descendants = reachable(forward)
        lowest = len(ancestors)
        highest = student_count - len(descendants) + 1
        values = list(range(lowest, highest + 1))
        answers.append(str(len(values)))
        answers.append(" ".join(str(value) for value in values))
    return "\n".join(answers) + "\n"


SAMPLE = """2
3 2 1
1 2
2 3
4 2 1
1 2
3 4
"""
SAMPLE_OUT = """1
1
3
1 2 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 3 1\n1 2\n2 3\n3 1\n") == "-1\n"
assert oracle("1\n1 0 1\n") == "1\n1\n"
assert oracle("1\n4 0 2\n") == "4\n1 2 3 4\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for student_count, edges, target in cases:
        text += f"{student_count} {len(edges)} {target}\n"
        for lower, higher in edges:
            text += f"{lower} {higher}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (3, [(1, 2), (2, 3), (3, 1)], 1),
        (1, [], 1),
        (4, [], 2),
        (2, [(1, 2)], 2),
    ])
    write("3_wide", [(500, [(node, node + 1) for node in range(1, 500)], 250)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(5):
        size = 30
        edges = [(lower, higher) for lower in range(1, size)
                 for higher in range(lower + 1, size + 1) if rng.random() < 0.08]
        random_cases.append((size, edges, rng.randint(1, size)))
    write("4_random", random_cases)
    write("5_io", [(500, [(250, 251)], 1)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, [(1, 2), (2, 3)], 1), (4, [(1, 2), (3, 4)], 1)])
build()
