#!/usr/bin/env python3
import heapq
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**9


def dijkstra(graph, source):
    distances = [INF] * len(graph)
    distances[source] = 0
    queue = [(0, source)]
    while queue:
        current, city = heapq.heappop(queue)
        if current != distances[city]:
            continue
        for neighbor, length in graph[city]:
            candidate = current + length
            if candidate < distances[neighbor]:
                distances[neighbor] = candidate
                heapq.heappush(queue, (candidate, neighbor))
    return distances


def oracle(text):
    tokens = [int(value) for value in text.split()]
    city_count = tokens[0]
    road_count = tokens[1]
    graph = [[] for _ in range(city_count)]
    cursor = 2
    for _ in range(road_count):
        first, second, length = tokens[cursor:cursor + 3]
        cursor += 3
        graph[first].append((second, length))
        graph[second].append((first, length))
    store_count = tokens[cursor]
    cursor += 1
    stores = tokens[cursor:cursor + store_count]
    cursor += store_count
    first_home, second_home = tokens[cursor:cursor + 2]
    origins = list(dict.fromkeys(stores + [first_home, second_home]))
    shortest = {origin: dijkstra(graph, origin) for origin in origins}
    best = INF
    for assignment in range(1 << store_count):
        first_group = [stores[index] for index in range(store_count) if assignment >> index & 1]
        second_group = [stores[index] for index in range(store_count) if not assignment >> index & 1]
        second_options = []
        for order in itertools.permutations(second_group):
            distance = 0
            previous = second_home
            for store in order:
                hop = shortest[previous][store]
                if hop >= INF:
                    break
                distance += hop
                previous = store
            else:
                second_options.append(distance)
        if not second_options:
            continue
        for order in itertools.permutations(first_group):
            distance = 0
            previous = first_home
            for store in order:
                hop = shortest[previous][store]
                if hop >= INF:
                    break
                distance += hop
                previous = store
            else:
                for second_distance in second_options:
                    if distance + second_distance < best:
                        best = distance + second_distance
    return str(best) + "\n"


SAMPLE = """5 6
0 1 5
1 4 1
0 4 10
0 2 2
1 2 3
2 3 4
2
2 4
0 1
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1\n0 1 7\n1\n0\n0 1\n") == "0\n"
assert oracle("3 3\n0 1 2\n1 2 2\n0 2 5\n1\n1\n0 2\n") == "2\n"
assert oracle("3 2\n0 1 4\n1 2 4\n2\n0 2\n0 1\n") == "4\n"


def write(name, city_count, edges, stores, homes):
    lines = [f"{city_count} {len(edges)}"]
    lines.extend(f"{first} {second} {length}" for first, second, length in edges)
    lines.append(str(len(stores)))
    lines.append(" ".join(str(store) for store in stores))
    lines.append(f"{homes[0]} {homes[1]}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2, [(0, 1, 7)], [0], (0, 1))
    write("3_wide", 8, [(0, 1, 2), (1, 2, 2), (2, 3, 2), (3, 4, 2), (4, 5, 2),
                         (5, 6, 2), (6, 7, 2), (0, 7, 20)], [2, 5], (0, 7))
    rng = random.Random(20261126)
    city_count = 10
    edges = [(index, index + 1, rng.randint(1, 9)) for index in range(city_count - 1)]
    for _ in range(12):
        first = rng.randrange(city_count)
        second = rng.randrange(city_count)
        if first != second:
            edges.append((first, second, rng.randint(1, 9)))
    write("4_random", city_count, edges, [1, 4, 7], (0, 9))

    big_count = 1000
    big_edges = [(index, index + 1, rng.randint(1, 20)) for index in range(big_count - 1)]
    for _ in range(1000):
        first = rng.randrange(big_count)
        second = rng.randrange(big_count)
        if first != second:
            big_edges.append((first, second, rng.randint(1, 20)))
    write("5_io", big_count, big_edges, [10, 250, 500, 750, 990], (0, 999))

    full_count = 100
    full_edges = [(first, second, rng.randint(1, 1000))
                  for first in range(full_count) for second in range(first + 1, full_count)]
    big_lines = [f"{full_count} {len(full_edges)}"]
    big_lines.extend(f"{first} {second} {length}" for first, second, length in full_edges)
    big_lines.append("8")
    big_lines.append(" ".join(str(index * 11) for index in range(8)))
    big_lines.append("3 97")
    Path("/tmp/INGRED_big.txt").write_text("\n".join(big_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, [(0, 1, 5), (1, 4, 1), (0, 4, 10), (0, 2, 2), (1, 2, 3), (2, 3, 4)],
      [2, 4], (0, 1))
build()
