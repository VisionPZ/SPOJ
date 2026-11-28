#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    numbers = list(map(int, text.split()))
    pos = 0
    answers = []
    while pos < len(numbers):
        node_count = numbers[pos]
        edge_count = numbers[pos + 1]
        query_count = numbers[pos + 2]
        pos += 3
        edges = []
        for _ in range(edge_count):
            source = numbers[pos]
            target = numbers[pos + 1]
            capacity = numbers[pos + 2]
            pos += 3
            edges.append((source, target, capacity))
        for _ in range(query_count):
            start = numbers[pos]
            weight = numbers[pos + 1]
            pos += 2
            reached = {start}
            frontier = [start]
            while frontier:
                nxt = []
                for node in frontier:
                    for source, target, capacity in edges:
                        if capacity < weight:
                            continue
                        other = None
                        if source == node:
                            other = target
                        elif target == node:
                            other = source
                        if other is not None and other not in reached:
                            reached.add(other)
                            nxt.append(other)
                frontier = nxt
            answers.append(str(len(reached)))
    return "\n".join(answers) + "\n"


SAMPLE = """4 4 3
1 2 4
2 3 3
3 0 4
0 1 3
1 3
1 4
1 5
"""
SAMPLE_OUT = """4
2
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 0 1\n0 1\n") == "1\n"
assert oracle("3 3 1\n0 1 10\n1 2 10\n0 2 10\n0 10\n") == "3\n"
assert oracle("3 3 1\n0 1 10\n1 2 10\n0 2 10\n0 11\n") == "1\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build_case(rng, node_count, edge_count, query_count):
    lines = [f"{node_count} {edge_count} {query_count}"]
    for _ in range(edge_count):
        first = rng.randrange(node_count)
        second = rng.randrange(node_count)
        if second == first:
            second = (second + 1) % node_count
        lines.append(f"{first} {second} {rng.randint(1, 100000)}")
    for _ in range(query_count):
        lines.append(f"{rng.randrange(node_count)} {rng.randint(1, 100000)}")
    return "\n".join(lines) + "\n"


def build():
    write("2_edges", "2 1 3\n0 1 5\n0 5\n0 6\n1 1\n")
    write("3_wide", build_case(random.Random(11), 60, 140, 40))
    rng = random.Random(20261126)
    write("4_random", build_case(rng, 45, 110, 60))
    write("5_io", build_case(random.Random(77), 20, 30, 30000))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
