#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for case_index in range(1, case_count + 1):
        node_count = tokens[cursor]
        cursor += 1
        edges = []
        for _ in range(node_count - 1):
            source = tokens[cursor]
            target = tokens[cursor + 1]
            cursor += 2
            edges.append((source, target))
        answers.append(f"Case {case_index}: {minimum_path_cover(node_count, edges)}")
    return "\n".join(answers) + "\n"


def minimum_path_cover(node_count, edges):
    reversed_edges = [(target, source) for source, target in edges]
    edge_count = len(reversed_edges)
    adjacency = [[] for _ in range(edge_count)]
    for first_index, (_, first_head) in enumerate(reversed_edges):
        for second_index, (second_tail, _) in enumerate(reversed_edges):
            if first_index != second_index and first_head == second_tail:
                adjacency[first_index].append(second_index)
    matched_target = [-1] * edge_count

    def augment(source_index, seen):
        for target_index in adjacency[source_index]:
            if target_index in seen:
                continue
            seen.add(target_index)
            if matched_target[target_index] == -1 or augment(matched_target[target_index], seen):
                matched_target[target_index] = source_index
                return True
        return False

    matching_size = 0
    for source_index in range(edge_count):
        if augment(source_index, set()):
            matching_size += 1
    return edge_count - matching_size


SAMPLE = """2
4
0 1
1 2
1 3
5
0 1
1 2
1 3
0 4
"""
SAMPLE_OUT = """Case 1: 2
Case 2: 3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert minimum_path_cover(4, [(0, 1), (1, 2), (1, 3)]) == 2
assert minimum_path_cover(5, [(0, 1), (1, 2), (1, 3), (0, 4)]) == 3
assert minimum_path_cover(2, [(0, 1)]) == 1
assert minimum_path_cover(3, [(0, 1), (1, 2)]) == 1


def random_case(rng, node_count):
    lines = [str(node_count)]
    for node in range(1, node_count):
        parent = rng.randrange(node)
        if rng.random() < 0.5:
            lines.append(f"{node} {parent}")
        else:
            lines.append(f"{parent} {node}")
    return "\n".join(lines)


def write(name, cases):
    text = str(len(cases)) + "\n" + "\n".join(cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [random_case(rng, size) for size in (2, 2, 3, 3, 4, 5)])
    write("3_wide", [random_case(rng, 12) for _ in range(8)])
    write("4_random", [random_case(rng, rng.randint(2, 12)) for _ in range(40)])
    write("5_io", [random_case(rng, rng.randint(2, 10)) for _ in range(400)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
