#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def maximal_cliques(road_count, adjacency):
    cliques = []

    def expand(used, candidates, excluded):
        if not candidates and not excluded:
            if len(used) >= 2:
                cliques.append(tuple(sorted(used)))
            return
        pivot_pool = candidates | excluded
        pivot = max(pivot_pool, key=lambda value: len(adjacency[value]))
        for vertex in list(candidates - adjacency[pivot]):
            expand(used | {vertex}, candidates & adjacency[vertex], excluded & adjacency[vertex])
            candidates.remove(vertex)
            excluded.add(vertex)

    expand(set(), set(range(road_count)), set())
    return sorted(cliques)


def maximal_cliques_subsets(road_count, adjacency):
    cliques = []
    for mask in range(1 << road_count):
        vertices = [index for index in range(road_count) if mask >> index & 1]
        if len(vertices) < 2:
            continue
        if any(second not in adjacency[first] for first, second in itertools.combinations(vertices, 2)):
            continue
        if any(set(vertices) < set(other) for other in cliques):
            continue
        cliques = [other for other in cliques if not set(other) < set(vertices)]
        cliques.append(tuple(vertices))
    return sorted(cliques)


def oracle_case(road_count, adjacency):
    cliques = maximal_cliques(road_count, adjacency)
    membership = [[] for _ in range(road_count)]
    for clique_index, clique in enumerate(cliques):
        for road_index in clique:
            membership[road_index].append(clique_index)
    if any(len(entry) > 2 for entry in membership):
        return "NO\n"
    city_count = len(cliques)
    city_edges = [[] for _ in range(city_count + road_count + 2)]
    edge_ends = []
    for road_index in range(road_count):
        entry = membership[road_index]
        if len(entry) == 2:
            first_city, second_city = entry
            edge_ends.append((first_city + 1, second_city + 1))
            city_edges[first_city].append(second_city)
            city_edges[second_city].append(first_city)
        elif len(entry) == 1:
            first_city = entry[0]
            second_city = city_count
            city_count += 1
            edge_ends.append((first_city + 1, second_city + 1))
            city_edges[first_city].append(second_city)
            city_edges[second_city].append(first_city)
        elif road_count == 1:
            edge_ends.append((1, 2))
            city_count = 2
            city_edges[0].append(1)
            city_edges[1].append(0)
        else:
            return "NO\n"
    if city_count != road_count + 1:
        return "NO\n"
    visited = {0}
    stack = [(0, -1)]
    while stack:
        city, parent = stack.pop()
        for neighbour in city_edges[city]:
            if neighbour == parent:
                continue
            if neighbour in visited:
                return "NO\n"
            visited.add(neighbour)
            stack.append((neighbour, city))
    if len(visited) != city_count:
        return "NO\n"
    for first_road in range(road_count):
        for second_road in range(first_road + 1, road_count):
            first_ends, second_ends = edge_ends[first_road], edge_ends[second_road]
            shared = bool(set(first_ends) & set(second_ends))
            if shared != (second_road in adjacency[first_road]):
                return "NO\n"
    return "YES\n" + "".join(f"{first} {second}\n" for first, second in edge_ends)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    road_count = tokens[0]
    cursor = 1
    adjacency = []
    for _ in range(road_count):
        degree = tokens[cursor]
        cursor += 1
        neighbours = {value - 1 for value in tokens[cursor:cursor + degree]}
        cursor += degree
        adjacency.append(neighbours)
    return oracle_case(road_count, adjacency)


SAMPLE = """3
2 3 2
2 1 3
2 2 1
"""
SAMPLE_OUT = """YES
1 2
1 3
1 4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n") == "YES\n1 2\n"
assert oracle("2\n1 2\n1 1\n") == "YES\n1 2\n1 3\n"
assert oracle("3\n1 2\n1 1\n0\n") == "NO\n"
assert maximal_cliques(3, [{1, 2}, {0, 2}, {0, 1}]) == [(0, 1, 2)]
assert maximal_cliques(4, [{1, 2, 3}, {0, 2, 3}, {0, 1, 3}, {0, 1, 2}]) == [(0, 1, 2, 3)]
for sample_adjacency in ([set()], [{1}, {0}], [{1, 2}, {0}, {0}], [{1, 3}, {0, 2}, {1, 3}, {0, 2}]):
    assert maximal_cliques(len(sample_adjacency), sample_adjacency) == \
           maximal_cliques_subsets(len(sample_adjacency), sample_adjacency)


def case(adjacency):
    lines = [str(len(adjacency))]
    for neighbours in adjacency:
        ordered = sorted(neighbours)
        lines.append(str(len(ordered)) + " " + " ".join(str(value + 1) for value in ordered))
    return "\n".join(lines) + "\n"


def tree_line_graph(edges, road_count):
    adjacency = [set() for _ in range(road_count)]
    for first_road in range(road_count):
        for second_road in range(first_road + 1, road_count):
            if set(edges[first_road]) & set(edges[second_road]):
                adjacency[first_road].add(second_road)
                adjacency[second_road].add(first_road)
    return adjacency


def prufer_edges(city_count, sequence):
    degree = [1] * city_count
    for value in sequence:
        degree[value] += 1
    remaining = list(sequence)
    edges = []
    for _ in range(city_count - 2):
        leaf = min(index for index in range(city_count) if degree[index] == 1)
        partner = remaining.pop(0)
        edges.append((leaf, partner))
        degree[leaf] -= 1
        degree[partner] -= 1
    first = next(index for index in range(city_count) if degree[index] == 1)
    second = next(index for index in range(city_count) if degree[index] == 1 and index != first)
    edges.append((first, second))
    return edges


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", case([{1, 3}, {0, 2}, {1, 3}, {0, 2}]))
    star = tree_line_graph([(0, city) for city in range(1, 7)], 6)
    write("3_wide", case(star))
    rng = random.Random(20261126)
    city_count = 8
    sequence = tuple(rng.randrange(city_count) for _ in range(city_count - 2))
    edges = prufer_edges(city_count, sequence)
    write("4_random", case(tree_line_graph(edges, city_count - 1)))
    edges = [(0, city) for city in range(1, 501)]
    write("5_io", case(tree_line_graph(edges, 500)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
