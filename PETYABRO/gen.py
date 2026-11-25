#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 18


def parse(text):
    tokens = text.split()
    city_count = int(tokens[0])
    road_count = int(tokens[1])
    cursor = 2
    flags = [int(value) for value in tokens[cursor:cursor + city_count]]
    cursor += city_count
    roads = []
    for _ in range(road_count):
        first = int(tokens[cursor]) - 1
        second = int(tokens[cursor + 1]) - 1
        cost = int(tokens[cursor + 2])
        cursor += 3
        roads.append((first, second, cost))
    return city_count, flags, roads


def shortest_paths(city_count, roads):
    distance = [[INF] * city_count for _ in range(city_count)]
    for index in range(city_count):
        distance[index][index] = 0
    for first, second, cost in roads:
        distance[first][second] = min(distance[first][second], cost)
        distance[second][first] = min(distance[second][first], cost)
    for middle in range(city_count):
        for first in range(city_count):
            for second in range(city_count):
                if distance[first][middle] + distance[middle][second] < distance[first][second]:
                    distance[first][second] = distance[first][middle] + distance[middle][second]
    return distance


def oracle(text):
    city_count, flags, roads = parse(text)
    distance = shortest_paths(city_count, roads)
    milkmen = [index for index in range(city_count) if flags[index] == 1]
    nearest = []
    for city in range(city_count):
        best = min((distance[city][milk] for milk in milkmen), default=INF)
        nearest.append(best)
    best_cost = None
    for mask in range(1 << len(roads)):
        parent = list(range(city_count))

        def find(city):
            while parent[city] != city:
                parent[city] = parent[parent[city]]
                city = parent[city]
            return city

        cost = 0
        for index, (first, second, road_cost) in enumerate(roads):
            if mask & (1 << index):
                first_root = find(first)
                second_root = find(second)
                if first_root != second_root:
                    parent[second_root] = first_root
                    cost += road_cost
        if best_cost is not None and cost >= best_cost:
            continue
        groups = {}
        for city in range(city_count):
            groups.setdefault(find(city), []).append(city)
        valid = True
        for members in groups.values():
            for city in members:
                if not any(flags[milk] and find(milk) == find(city)
                           and distance[city][milk] == nearest[city]
                           for milk in milkmen):
                    valid = False
                    break
            if not valid:
                break
        if valid and (best_cost is None or cost < best_cost):
            best_cost = cost
    if best_cost is None:
        return "impossible\n"
    return str(best_cost) + "\n"


SAMPLE = """5 7
0 1 0 1 0
1 2 11
1 3 1
1 5 17
2 3 1
3 5 18
4 5 3
2 4 5
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 0\n1 0\n") == "impossible\n"
assert oracle("2 1\n1 0\n1 2 7\n") == "7\n"
assert oracle("3 2\n1 0 0\n1 2 3\n2 3 4\n") == "7\n"


def write(name, city_count, flags, roads):
    text = f"{city_count} {len(roads)}\n"
    text += " ".join(str(value) for value in flags) + "\n"
    text += "\n".join(f"{first + 1} {second + 1} {cost}" for first, second, cost in roads) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def has_unique_nearest(city_count, flags, roads):
    distance = shortest_paths(city_count, roads)
    for city in range(city_count):
        values = sorted(distance[city][milk] for milk in range(city_count) if flags[milk])
        if values and len(values) > 1 and values[0] == values[1]:
            return False
    return True


def build():
    write("2_edges", 4, [1, 1, 0, 0], [(0, 2, 2), (1, 3, 3), (2, 3, 5), (0, 1, 9)])
    rng = random.Random(20261126)
    for name, count, size in [("3_wide", 30, 7), ("4_random", 30, 6), ("5_io", 40, 7)]:
        while True:
            city_count = size
            flags = [1 if index == 0 else 0 for index in range(city_count)]
            flags[city_count // 2] = 1
            pairs = list(itertools.combinations(range(city_count), 2))
            rng.shuffle(pairs)
            chosen = pairs[:count]
            roads = [(first, second, rng.randint(1, 1000)) for first, second in chosen]
            if has_unique_nearest(city_count, flags, roads):
                break
        write(name, city_count, flags, roads)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
