#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    position = 0
    test_count = int(tokens[position])
    position += 1
    result = []
    for _ in range(test_count):
        hostel_count = int(tokens[position])
        position += 1
        edges = []
        for _ in range(hostel_count - 1):
            first_hostel = int(tokens[position])
            second_hostel = int(tokens[position + 1])
            position += 2
            edges.append((first_hostel, second_hostel))
        query_count = int(tokens[position])
        position += 1
        removed = set()
        answers = []
        for _ in range(query_count):
            kind = tokens[position]
            position += 1
            if kind == "R":
                removed.add(int(tokens[position]))
                position += 1
                continue
            adjacency = {hostel: [] for hostel in range(1, hostel_count + 1)}
            for edge_number, (first_hostel, second_hostel) in enumerate(edges, start=1):
                if edge_number in removed:
                    continue
                adjacency[first_hostel].append(second_hostel)
                adjacency[second_hostel].append(first_hostel)
            seen = set()
            connected_pairs = 0
            for start in range(1, hostel_count + 1):
                if start in seen:
                    continue
                stack = [start]
                seen.add(start)
                component_size = 0
                while stack:
                    node = stack.pop()
                    component_size += 1
                    for neighbour in adjacency[node]:
                        if neighbour not in seen:
                            seen.add(neighbour)
                            stack.append(neighbour)
                connected_pairs += component_size * (component_size - 1) // 2
            total_pairs = hostel_count * (hostel_count - 1) // 2
            answers.append(str(total_pairs - connected_pairs))
        result.extend(answers)
        result.append("")
    return "\n".join(result) + "\n"


SAMPLE = """2

3
1 2
1 3
5
Q
R 1
Q
R 2
Q

4
1 2
1 3
1 4
7
Q
R 1
Q
R 2
Q
R 3
Q
"""
SAMPLE_OUT = """0
2
3

0
3
5
6

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n1 2\n3\nQ\nR 1\nQ\n") == "0\n1\n\n"
assert oracle("1\n4\n1 2\n2 3\n3 4\n1\nQ\n") == "0\n\n"
assert oracle("1\n5\n1 2\n2 3\n3 4\n4 5\n2\nR 2\nQ\n") == "6\n\n"


def random_tree(rng, size):
    edges = []
    for node in range(2, size + 1):
        parent = rng.randint(1, node - 1)
        edges.append((parent, node))
    rng.shuffle(edges)
    return edges


def render(test_cases):
    blocks = [str(len(test_cases))]
    for edges, query_count, seed in test_cases:
        size = len(edges) + 1
        blocks.append(str(size))
        for first_hostel, second_hostel in edges:
            blocks.append(f"{first_hostel} {second_hostel}")
        rng = random.Random(seed)
        order = list(range(1, len(edges) + 1))
        rng.shuffle(order)
        removals = order[:query_count // 2]
        blocks.append(str(query_count))
        removed_index = 0
        for query_index in range(query_count):
            if removed_index < len(removals) and query_index % 2 == 1:
                blocks.append("R " + str(removals[removed_index]))
                removed_index += 1
            else:
                blocks.append("Q")
        blocks.append("")
    return "\n".join(blocks) + "\n"


def write(name, test_cases):
    text = render(test_cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [([(1, 2)], 3, 11), ([(1, 2), (1, 3), (1, 4)], 7, 12)])
    rng = random.Random(20261126)
    wide = []
    for seed in range(5):
        size = 20
        wide.append((random_tree(rng, size), 25, 1000 + seed))
    write("3_wide", wide)
    many = []
    for seed in range(3):
        size = 12
        many.append((random_tree(rng, size), 20, 2000 + seed))
    write("4_random", many)
    heavy = []
    for seed in range(2):
        size = 60
        heavy.append((random_tree(rng, size), 100, 3000 + seed))
    write("5_io", heavy)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
