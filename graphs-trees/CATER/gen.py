#!/usr/bin/env python3
import itertools
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 10243


def oracle(text):
    tokens = [int(value) for value in text.split()]
    station_count = tokens[0]
    group_size = tokens[1]
    adjacency = [[] for _ in range(station_count + 1)]
    cursor = 2
    for _ in range(station_count - 1):
        endpoint_one = tokens[cursor]
        endpoint_two = tokens[cursor + 1]
        cursor += 2
        adjacency[endpoint_one].append(endpoint_two)
        adjacency[endpoint_two].append(endpoint_one)
    legal = 0
    for subset in itertools.combinations(range(1, station_count + 1), group_size):
        chosen = set(subset)
        reached = {subset[0]}
        queue = deque([subset[0]])
        while queue:
            current = queue.popleft()
            for neighbor in adjacency[current]:
                if neighbor in chosen and neighbor not in reached:
                    reached.add(neighbor)
                    queue.append(neighbor)
        if len(reached) == group_size:
            legal += 1
    return str(legal % MODULUS) + "\n"


SAMPLE = """6 3
1 2
2 5
3 2
4 5
6 5
"""
SAMPLE_OUT = """6
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n") == "1\n"
assert oracle("2 1\n1 2\n") == "2\n"
assert oracle("3 2\n1 2\n2 3\n") == "2\n"
assert oracle("4 3\n1 2\n2 3\n3 4\n") == "2\n"


def write(name, station_count, group_size, edges):
    text = f"{station_count} {group_size}\n" + "".join(
        f"{endpoint_one} {endpoint_two}\n" for endpoint_one, endpoint_two in edges)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 6, 2, [(1, 2), (1, 3), (1, 4), (4, 5), (4, 6)])
    write("3_wide", 8, 4, [(1, 2), (2, 3), (2, 4), (1, 5), (5, 6), (5, 7), (7, 8)])
    rng = random.Random(20261126)
    edges = [(rng.randint(1, index - 1), index) for index in range(2, 10)]
    write("4_random", 9, 3, edges)
    write("5_io", 11, 5, [(1, 2), (2, 3), (3, 4), (4, 5), (5, 6),
                           (6, 7), (7, 8), (8, 9), (9, 10), (10, 11), (1, 11)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 6, 3, [(1, 2), (2, 5), (3, 2), (4, 5), (6, 5)])
build()
