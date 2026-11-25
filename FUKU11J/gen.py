#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 12


def parse(text):
    tokens = iter(text.split())
    datasets = []
    while True:
        town_count = int(next(tokens))
        road_count = int(next(tokens))
        if town_count == 0 and road_count == 0:
            break
        fees = [0] * town_count
        altitudes = [0] * town_count
        altitudes[-1] = 1000
        for town_index in range(1, town_count - 1):
            fees[town_index] = int(next(tokens))
            altitudes[town_index] = int(next(tokens))
        roads = []
        for _ in range(road_count):
            first = int(next(tokens)) - 1
            second = int(next(tokens)) - 1
            cost = int(next(tokens))
            roads.append((first, second, cost))
        datasets.append((town_count, fees, altitudes, roads))
    return datasets


def oracle(text):
    answers = []
    for town_count, fees, altitudes, roads in parse(text):
        go_graph = [[] for _ in range(town_count)]
        return_graph = [[] for _ in range(town_count)]
        for first, second, cost in roads:
            if altitudes[first] <= altitudes[second]:
                go_graph[first].append((second, cost))
            if altitudes[first] >= altitudes[second]:
                return_graph[second].append((first, cost))

        def enumerate_paths(graph):
            found = []
            def walk(town, cost, visited):
                if town == town_count - 1:
                    found.append((cost, frozenset(visited)))
                    return
                for nxt, road_cost in graph[town]:
                    if nxt not in visited:
                        walk(nxt, cost + road_cost, visited + [nxt])
            walk(0, 0, [0])
            return found

        go_paths = enumerate_paths(go_graph)
        return_paths = enumerate_paths(return_graph)
        if not go_paths or not return_paths:
            answers.append("-1")
            continue
        best = INF
        for go_cost, go_visited in go_paths:
            for return_cost, return_visited in return_paths:
                fee_total = sum(fees[town] for town in go_visited | return_visited)
                best = min(best, go_cost + return_cost + fee_total)
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """3 6
3 1
1 2 1
2 3 1
3 2 1
2 1 1
1 3 4
3 1 4
3 6
5 1
1 2 1
2 3 1
3 2 1
2 1 1
1 3 4
3 1 4
4 5
3 1
3 1
1 2 5
2 3 5
3 4 5
4 2 5
3 1 5
2 1
2 1 1
0 0
"""
SAMPLE_OUT = """7
8
36
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1\n1 2 1\n0 0\n") == "-1\n"
assert oracle("2 2\n1 2 1\n2 1 1\n0 0\n") == "2\n"
assert oracle("3 2\n1 1\n1 2 1\n2 3 1\n0 0\n") == "-1\n"


def render(datasets):
    lines = []
    for town_count, fees, altitudes, roads in datasets:
        lines.append(f"{town_count} {len(roads)}")
        for town_index in range(1, town_count - 1):
            lines.append(f"{fees[town_index]} {altitudes[town_index]}")
        for first, second, cost in roads:
            lines.append(f"{first + 1} {second + 1} {cost}")
    lines.append("0 0")
    return "\n".join(lines) + "\n"


def random_dataset(rng, town_count, density):
    fees = [0] * town_count
    altitudes = [0] + [rng.randint(1, 6) for _ in range(town_count - 2)] + [1000]
    for town_index in range(1, town_count - 1):
        fees[town_index] = rng.randint(1, 6)
    roads = []
    for first in range(town_count):
        for second in range(town_count):
            if first != second and rng.random() < density:
                roads.append((first, second, rng.randint(1, 6)))
    return town_count, fees, altitudes, roads


def write(name, datasets):
    text = render(datasets)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (2, [0, 0], [0, 1000], []),
        (2, [0, 0], [0, 1000], [(0, 1, 1)]),
        (2, [0, 0], [0, 1000], [(0, 1, 1), (1, 0, 3)]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [random_dataset(rng, 7, 0.55) for _ in range(3)])
    write("4_random", [random_dataset(rng, rng.randint(3, 6), 0.45) for _ in range(8)])
    write("5_io", [random_dataset(rng, rng.randint(2, 5), 0.5) for _ in range(60)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
