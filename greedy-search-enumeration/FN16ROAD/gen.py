#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

from scipy.optimize import linprog

ROOT = Path(__file__).resolve().parent


def format_bound(value):
    text = f"{value:.6f}"
    while len(text) > 2 and text.endswith("0") and text[-2] != ".":
        text = text[:-1]
    return text


def shortest_paths(distances):
    city_count = len(distances)
    all_dist = []
    all_prev = []
    all_counts = []
    for source in range(city_count):
        best = [None] * city_count
        best[source] = 0
        heap = [(0, source)]
        while heap:
            cost, node = heapq.heappop(heap)
            if cost != best[node]:
                continue
            for neighbour in range(city_count):
                road = distances[node][neighbour]
                if road < 0:
                    continue
                candidate = cost + road
                if best[neighbour] is None or candidate < best[neighbour]:
                    best[neighbour] = candidate
                    heapq.heappush(heap, (candidate, neighbour))
        previous = [None] * city_count
        for node in range(city_count):
            if node == source or best[node] is None:
                continue
            for neighbour in range(city_count):
                if neighbour == node:
                    continue
                road = distances[neighbour][node]
                if road >= 0 and best[neighbour] is not None and best[neighbour] + road == best[node]:
                    previous[node] = neighbour
        counts = [0] * city_count
        counts[source] = 1
        order = sorted((cost, node) for node, cost in enumerate(best) if cost is not None)
        for _, node in order:
            for neighbour in range(city_count):
                if neighbour == node:
                    continue
                road = distances[node][neighbour]
                if road >= 0 and best[neighbour] is not None:
                    if best[node] + road == best[neighbour]:
                        counts[neighbour] += counts[node]
        all_dist.append(best)
        all_prev.append(previous)
        all_counts.append(counts)
    return all_dist, all_prev, all_counts


def route_to_edges(source, target, previous, edge_ids):
    route = []
    node = target
    while node != source:
        ancestor = previous[node]
        route.append(edge_ids[ancestor][node])
        node = ancestor
    route.reverse()
    return route


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        city_count = tokens[cursor]
        cursor += 1
        distances = []
        for _ in range(city_count):
            distances.append(tokens[cursor:cursor + city_count])
            cursor += city_count
        edges = []
        edge_ids = [[-1] * city_count for _ in range(city_count)]
        for source in range(city_count):
            for target in range(city_count):
                length = distances[source][target]
                if length > 0:
                    edge_ids[source][target] = len(edges)
                    edges.append((source, target, length))
        edge_count = len(edges)
        all_dist, all_prev, all_counts = shortest_paths(distances)
        observed_count = tokens[cursor]
        cursor += 1
        observations = []
        for _ in range(observed_count):
            source = tokens[cursor]
            target = tokens[cursor + 1]
            minutes = tokens[cursor + 2]
            cursor += 3
            observations.append((source, target, minutes))
        query_count = tokens[cursor]
        cursor += 1
        queries = []
        for _ in range(query_count):
            source = tokens[cursor]
            target = tokens[cursor + 1]
            cursor += 2
            queries.append((source, target))

        equality_rows = []
        equality_rhs = []
        for edge_index, (_, _, length) in enumerate(edges):
            row = [0.0] * (2 * edge_count)
            row[edge_index] = 1.0
            row[edge_count + edge_index] = 1.0
            equality_rows.append(row)
            equality_rhs.append(float(length))
        for source, target, minutes in observations:
            route = route_to_edges(source, target, all_prev[source], edge_ids)
            row = [0.0] * (2 * edge_count)
            for edge_index in route:
                row[edge_index] = 1.0
            equality_rows.append(row)
            equality_rhs.append(float(minutes - sum(edges[index][2] for index in route)))
        bounds = [(0, None)] * edge_count + [(0, float(edges[index][2])) for index in range(edge_count)]
        for source, target in queries:
            route = route_to_edges(source, target, all_prev[source], edge_ids)
            objective = [0.0] * (2 * edge_count)
            for edge_index in route:
                objective[edge_index] = 1.0
            base = sum(edges[index][2] for index in route)
            minimum = linprog(objective, A_eq=equality_rows, b_eq=equality_rhs,
                              bounds=bounds, method="highs")
            maximum = linprog([-value for value in objective], A_eq=equality_rows,
                              b_eq=equality_rhs, bounds=bounds, method="highs")
            answers.append(f"{source} {target} {format_bound(base + minimum.fun)} "
                           f"{format_bound(base - maximum.fun)}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
0 50 -1
55 0 40
-1 40 0
1
0 2 120
3
0 1
1 2
1 0
"""
SAMPLE_OUT = """0 1 50.0 80.0
1 2 40.0 70.0
1 0 55.0 110.0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert format_bound(50.0) == "50.0"
assert format_bound(33.333333333) == "33.333333"


def make_case(rng, city_count, density, observed_count, query_count):
    distances = [[-1] * city_count for _ in range(city_count)]
    for source in range(city_count):
        distances[source][source] = 0
    for source in range(city_count):
        for target in range(city_count):
            if source != target and rng.random() < density:
                distances[source][target] = rng.randint(1, 60)
    all_dist, all_prev, all_counts = shortest_paths(distances)
    edges = []
    edge_ids = [[-1] * city_count for _ in range(city_count)]
    for source in range(city_count):
        for target in range(city_count):
            if distances[source][target] > 0:
                edge_ids[source][target] = len(edges)
                edges.append((source, target, distances[source][target]))
    actual_times = [rng.randint(edge[2], 2 * edge[2]) for edge in edges]
    good_pairs = []
    for source in range(city_count):
        for target in range(city_count):
            if source == target:
                continue
            if all_dist[source][target] is None:
                continue
            if all_counts[source][target] != 1:
                continue
            route = route_to_edges(source, target, all_prev[source], edge_ids)
            good_pairs.append((source, target, route))
    rng.shuffle(good_pairs)
    if len(good_pairs) < observed_count + query_count:
        return None
    observations = []
    for source, target, route in good_pairs[:observed_count]:
        observations.append((source, target, sum(actual_times[index] for index in route)))
    queries = [(source, target) for source, target, _ in
               good_pairs[observed_count:observed_count + query_count]]
    parts = [str(city_count)]
    for row in distances:
        parts.append(" ".join(str(value) for value in row))
    parts.append(str(len(observations)))
    for source, target, minutes in observations:
        parts.append(f"{source} {target} {minutes}")
    parts.append(str(len(queries)))
    for source, target in queries:
        parts.append(f"{source} {target}")
    return "\n".join(parts) + "\n"


def write(name, cases):
    text = "".join(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    small = []
    while len(small) < 6:
        case = make_case(rng, 3, 0.9, 1, 3)
        if case:
            small.append(case)
    write("2_edges", small)
    wide = []
    while len(wide) < 3:
        case = make_case(rng, 12, 0.3, 3, 6)
        if case:
            wide.append(case)
    write("3_wide", wide)
    random_cases = []
    while len(random_cases) < 5:
        case = make_case(rng, 6, 0.6, 2, 5)
        if case:
            random_cases.append(case)
    write("4_random", random_cases)
    io_cases = []
    while len(io_cases) < 20:
        case = make_case(rng, 10, 0.4, 3, 30)
        if case:
            io_cases.append(case)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
