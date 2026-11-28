#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 18


def parse(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    farm_count = tokens[cursor]; cursor += 1
    flight_count = tokens[cursor]; cursor += 1
    hub_count = tokens[cursor]; cursor += 1
    trip_count = tokens[cursor]; cursor += 1
    edges = []
    for _ in range(flight_count):
        origin = tokens[cursor]; cursor += 1
        destination = tokens[cursor]; cursor += 1
        cost = tokens[cursor]; cursor += 1
        edges.append((origin - 1, destination - 1, cost))
    trips = []
    for _ in range(trip_count):
        start = tokens[cursor]; cursor += 1
        end = tokens[cursor]; cursor += 1
        trips.append((start - 1, end - 1))
    return farm_count, hub_count, edges, trips


def oracle(text):
    farm_count, hub_count, edges, trips = parse(text)
    matrix = [[INF] * farm_count for _ in range(farm_count)]
    for node in range(farm_count):
        matrix[node][node] = 0
    for origin, destination, cost in edges:
        if cost < matrix[origin][destination]:
            matrix[origin][destination] = cost
    for middle in range(farm_count):
        row_middle = matrix[middle]
        for origin in range(farm_count):
            row_origin = matrix[origin]
            via = row_origin[middle]
            if via >= INF:
                continue
            for destination in range(farm_count):
                candidate = via + row_middle[destination]
                if candidate < row_origin[destination]:
                    row_origin[destination] = candidate
    possible = 0
    total = 0
    for start, end in trips:
        best = INF
        for hub in range(hub_count):
            candidate = matrix[start][hub] + matrix[hub][end]
            if candidate < best:
                best = candidate
        if best < INF:
            possible += 1
            total += best
    return f"{possible}\n{total}\n"


def dijkstra_check(text):
    farm_count, hub_count, edges, trips = parse(text)
    adjacency = [[] for _ in range(farm_count)]
    reversed_adjacency = [[] for _ in range(farm_count)]
    for origin, destination, cost in edges:
        adjacency[origin].append((destination, cost))
        reversed_adjacency[destination].append((origin, cost))

    def run(graph, source):
        distances = [INF] * farm_count
        distances[source] = 0
        heap = [(0, source)]
        while heap:
            distance, node = heapq.heappop(heap)
            if distance > distances[node]:
                continue
            for neighbor, cost in graph[node]:
                candidate = distance + cost
                if candidate < distances[neighbor]:
                    distances[neighbor] = candidate
                    heapq.heappush(heap, (candidate, neighbor))
        return distances

    forward = [run(adjacency, hub) for hub in range(hub_count)]
    backward = [run(reversed_adjacency, hub) for hub in range(hub_count)]
    possible = 0
    total = 0
    for start, end in trips:
        best = min((backward[hub][start] + forward[hub][end] for hub in range(hub_count)), default=INF)
        if best < INF:
            possible += 1
            total += best
    return f"{possible}\n{total}\n"


SAMPLE = """3 3 1 3
3 1 10
1 3 10
1 2 7
3 2
2 3
1 2
"""
SAMPLE_OUT = """2
24
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert dijkstra_check(SAMPLE) == SAMPLE_OUT
assert oracle("2 0 1 1\n2 1\n") == "0\n0\n"
assert oracle("2 1 1 1\n1 2 5\n2 1\n") == "0\n0\n"
assert oracle("2 1 1 1\n1 2 5\n1 2\n") == "1\n5\n"
assert dijkstra_check("3 3 2 2\n1 2 4\n2 3 6\n3 1 2\n3 1\n2 1\n") == oracle("3 3 2 2\n1 2 4\n2 3 6\n3 1 2\n3 1\n2 1\n")


def write(name, farm_count, hub_count, edges, trips):
    lines = [f"{farm_count} {len(edges)} {hub_count} {len(trips)}"]
    lines.extend(f"{origin} {destination} {cost}" for origin, destination, cost in edges)
    lines.extend(f"{start} {end}" for start, end in trips)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 2, 1, [], [(2, 1)])
    rng = random.Random(20261126)
    edges = []
    for node in range(1, 40):
        edges.append((node, node + 1, rng.randint(1, 1000000)))
    for _ in range(60):
        origin = rng.randint(1, 40)
        destination = rng.randint(1, 40)
        edges.append((origin, destination, rng.randint(1, 1000000)))
    trips = [(rng.randint(1, 40), rng.randint(1, 40)) for _ in range(200)]
    write("3_wide", 40, 10, edges, trips)

    edges = []
    for node in range(1, 30):
        edges.append((node, node + 1, rng.randint(1, 1000000)))
        edges.append((node + 1, node, rng.randint(1, 1000000)))
    for _ in range(80):
        origin = rng.randint(1, 30)
        destination = rng.randint(1, 30)
        edges.append((origin, destination, rng.randint(1, 1000000)))
    trips = [(rng.randint(1, 30), rng.randint(1, 30)) for _ in range(200)]
    write("4_random", 30, 8, edges, trips)

    edges = []
    for node in range(1, 30):
        edges.append((node, node + 1, rng.randint(1, 1000000)))
        edges.append((node + 1, node, rng.randint(1, 1000000)))
    for _ in range(100):
        origin = rng.randint(1, 30)
        destination = rng.randint(1, 30)
        edges.append((origin, destination, rng.randint(1, 1000000)))
    trips = [(rng.randint(1, 30), rng.randint(1, 30)) for _ in range(10000)]
    write("5_io", 30, 8, edges, trips)


def trace_example():
    print("hub farm: 1")
    print("3 -> 1 -> 2 cost: 10 + 7 = 17")
    print("2 has no outgoing flight, so no route")
    print("1 -> 2 cost: 0 + 7 = 7")
    print("count = 2, sum = 24")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, 1, [(3, 1, 10), (1, 3, 10), (1, 2, 7)], [(3, 2), (2, 3), (1, 2)])
build()
trace_example()
