#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def enumerate_cycles(city_total, roads):
    adjacency = [[] for _ in range(city_total + 1)]
    for edge_id, (first_city, second_city) in enumerate(roads):
        adjacency[first_city].append((edge_id, second_city))
        adjacency[second_city].append((edge_id, first_city))
    cycles = set()
    for start in range(1, city_total + 1):
        visited = {start}
        path_edges = []

        def walk(current):
            for edge_id, neighbor in adjacency[current]:
                if neighbor == start:
                    if len(path_edges) >= 2:
                        cycles.add(frozenset(path_edges + [edge_id]))
                elif neighbor > start and neighbor not in visited:
                    visited.add(neighbor)
                    path_edges.append(edge_id)
                    walk(neighbor)
                    path_edges.pop()
                    visited.remove(neighbor)

        walk(start)
    return cycles


def region_supplies(city_total, supplies, roads):
    cycles = enumerate_cycles(city_total, roads)
    parent = list(range(len(roads)))

    def find(node):
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    for cycle in cycles:
        members = list(cycle)
        for other in members[1:]:
            first_root = find(members[0])
            second_root = find(other)
            if first_root != second_root:
                parent[second_root] = first_root

    groups = {}
    for edge_id, (first_city, second_city) in enumerate(roads):
        groups.setdefault(find(edge_id), set()).update((first_city, second_city))
    results = [sum(supplies[city] for city in members) for members in groups.values()]
    connected_cities = set()
    for members in groups.values():
        connected_cities.update(members)
    for city in range(1, city_total + 1):
        if city not in connected_cities:
            results.append(supplies[city])
    return results


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_total = tokens[0]
    lines = []
    cursor = 1
    for case_number in range(1, case_total + 1):
        city_total = tokens[cursor]
        road_total = tokens[cursor + 1]
        toy_total = tokens[cursor + 2]
        cursor += 3
        supplies = [0] + tokens[cursor:cursor + city_total]
        cursor += city_total
        demands = tokens[cursor:cursor + toy_total]
        cursor += toy_total
        roads = []
        for _ in range(road_total):
            roads.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2

        supplies_per_region = region_supplies(city_total, supplies, roads)
        region_total = len(supplies_per_region)
        line = f"Buzz Mission {case_number}: {region_total} "
        if region_total > toy_total:
            line += "No"
        else:
            best = None
            for assignment in itertools.permutations(demands, region_total):
                waste = max(abs(demand - supply) for demand, supply in zip(assignment, supplies_per_region))
                if best is None or waste < best:
                    best = waste
            line += str(best)
        lines.append(line)
    return "\n".join(lines) + "\n"


SAMPLE = """2
6 7 3
5 4 8 1 2 6
10 14 9
1 2
2 3
3 1
3 4
4 5
3 5
5 6
4 3 1
5 4 8 1
10
1 2
2 3
3 1
"""
SAMPLE_OUT = """Buzz Mission 1: 3 3
Buzz Mission 2: 2 No
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 0 3\n5 4 8\n10 14 9\n") == "Buzz Mission 1: 3 6\n"
assert oracle("1\n3 3 1\n5 4 8\n10\n1 2\n2 3\n3 1\n") == "Buzz Mission 1: 1 7\n"
assert oracle("1\n2 1 2\n5 7\n10 12\n1 2\n") == "Buzz Mission 1: 1 0\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for supplies, demands, roads in cases:
        text += f"{len(supplies)} {len(roads)} {len(demands)}\n"
        text += " ".join(str(value) for value in supplies) + "\n"
        text += " ".join(str(value) for value in demands) + "\n"
        text += "".join(f"{first_city} {second_city}\n" for first_city, second_city in roads)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([5, 7, 9], [10, 12, 14], []),
        ([5, 7], [10, 12], [(1, 2)]),
        ([5, 7, 9], [10], [(1, 2), (2, 3), (3, 1)]),
    ])
    cycle = ([(index, index + 1) for index in range(1, 7)] + [(7, 1)])
    write("3_wide", [([100 + index for index in range(7)], [200, 300, 400], cycle)])
    rng = random.Random(20261126)
    cases = []
    for _ in range(10):
        city_total = rng.randint(2, 7)
        supplies = [rng.randint(1, 999) for _ in range(city_total)]
        toy_total = rng.randint(1, 7)
        demands = [rng.randint(1, 999) for _ in range(toy_total)]
        roads = []
        for first_city in range(1, city_total + 1):
            for second_city in range(first_city + 1, city_total + 1):
                if rng.random() < 0.35:
                    roads.append((first_city, second_city))
        cases.append((supplies, demands, roads))
    write("4_random", cases)
    cases = []
    for _ in range(100):
        city_total = rng.randint(1, 5)
        supplies = [rng.randint(1, 999) for _ in range(city_total)]
        demands = [rng.randint(1, 999) for _ in range(city_total)]
        roads = [(1, 2), (2, 3)] if city_total >= 3 else []
        roads = [(first, second) for first, second in roads if first <= city_total and second <= city_total]
        cases.append((supplies, demands, roads))
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_cases = [
    ([5, 4, 8, 1, 2, 6], [10, 14, 9],
     [(1, 2), (2, 3), (3, 1), (3, 4), (4, 5), (3, 5), (5, 6)]),
    ([5, 4, 8, 1], [10], [(1, 2), (2, 3), (3, 1)]),
]
write("1_sample", sample_cases)
build()

rng = random.Random(19471208)
big_cases = []
for _ in range(100):
    city_total = 251
    supplies = [rng.randint(1, 999) for _ in range(city_total)]
    demands = [rng.randint(1, 999) for _ in range(city_total)]
    roads = []
    for first_city in range(1, city_total + 1):
        for second_city in range(first_city + 1, city_total + 1):
            if rng.random() < 0.05:
                roads.append((first_city, second_city))
    big_cases.append((supplies, demands, roads))
big_text = str(len(big_cases)) + "\n"
for supplies, demands, roads in big_cases:
    big_text += f"{len(supplies)} {len(roads)} {len(demands)}\n"
    big_text += " ".join(str(value) for value in supplies) + "\n"
    big_text += " ".join(str(value) for value in demands) + "\n"
    big_text += "".join(f"{first_city} {second_city}\n" for first_city, second_city in roads)
Path("/tmp/BUZZ_big.txt").write_text(big_text)
