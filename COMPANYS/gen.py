#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def spanning_trees(city_count, edges):
    for subset in itertools.combinations(range(len(edges)), city_count - 1):
        parent = list(range(city_count))

        def find(node):
            while parent[node] != node:
                parent[node] = parent[parent[node]]
                node = parent[node]
            return node

        total_cost = 0
        telecom_count = 0
        for edge_index in subset:
            first, second, cost, company = edges[edge_index]
            first_root = find(first)
            second_root = find(second)
            if first_root != second_root:
                parent[first_root] = second_root
            total_cost += cost
            if company == 0:
                telecom_count += 1
        if len({find(node) for node in range(city_count)}) == 1:
            yield telecom_count, total_cost


def oracle(cases):
    answers = []
    for index, (city_count, required, edges) in enumerate(cases):
        best = None
        for telecom_count, total_cost in spanning_trees(city_count, edges):
            if telecom_count == required and (best is None or total_cost < best):
                best = total_cost
        assert best is not None, "generator produced an unsolvable case"
        answers.append(f"Case {index + 1}: {best}")
    return "\n".join(answers) + "\n"


def solvable_case(rng, city_count, cable_count):
    while True:
        edges = []
        for _ in range(cable_count):
            first = rng.randrange(city_count)
            second = rng.randrange(city_count)
            if first == second:
                second = (second + 1) % city_count
            edges.append((first, second, rng.randint(1, 100), rng.randint(0, 1)))
        reachable = {telecom for telecom, _ in spanning_trees(city_count, edges)}
        if reachable:
            return city_count, rng.choice(sorted(reachable)), edges


SAMPLE_CASES = [(2, 1, [(0, 1, 1, 1), (0, 1, 2, 0)]),
                (2, 0, [(0, 1, 1, 1), (0, 1, 2, 0)])]
SAMPLE = "2 2 1\n0 1 1 1\n0 1 2 0\n2 2 0\n0 1 1 1\n0 1 2 0\n"
SAMPLE_OUT = "Case 1: 2\nCase 2: 1\n"
assert oracle(SAMPLE_CASES) == SAMPLE_OUT
assert oracle([(2, 1, [(0, 1, 9, 0), (0, 1, 1, 1)])]) == "Case 1: 9\n"
assert oracle([(2, 0, [(0, 1, 9, 0), (0, 1, 1, 1)])]) == "Case 1: 1\n"
assert oracle([(3, 2, [(0, 1, 5, 0), (1, 2, 7, 0), (0, 2, 1, 1)])]) == "Case 1: 12\n"


def write(name, cases):
    parts = []
    for city_count, required, edges in cases:
        parts.append(f"{city_count} {len(edges)} {required}")
        parts.extend(f"{first} {second} {cost} {company}"
                     for first, second, cost, company in edges)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def build():
    rng = random.Random(20261126)
    edges_line = [(0, 1, 1, 1), (0, 1, 2, 0)]
    write("2_edges", [(1, 0, []), (2, 0, edges_line), (2, 1, edges_line),
                      (3, 0, [(0, 1, 4, 1), (1, 2, 6, 1), (0, 2, 2, 1)]),
                      (3, 2, [(0, 1, 4, 0), (1, 2, 6, 0), (0, 2, 2, 1)])])
    wide_cases = []
    for _ in range(60):
        cities = rng.randint(4, 8)
        wide_cases.append(solvable_case(rng, cities,
                                        rng.randint(cities - 1, 12)))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(300):
        cities = rng.randint(2, 6)
        random_cases.append(solvable_case(rng, cities,
                                          rng.randint(cities - 1, 9)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20000):
        cities = rng.choice([2, 3])
        io_cases.append(solvable_case(rng, cities,
                                      rng.randint(cities - 1, 4)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
