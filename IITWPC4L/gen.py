#!/usr/bin/env python3
import heapq
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 15


def min_cost_flow(case):
    door_count, required, keys, powers = case
    key_start = min(keys) - 5 * required
    key_count = max(keys) + 5 * required - key_start + 1
    source = 0
    first_door = 1
    first_key = 1 + door_count
    sink = first_key + key_count
    size = sink + 1
    graph = [[] for _ in range(size)]

    def add_edge(origin, destination, capacity, cost):
        forward = [destination, len(graph[destination]), capacity, cost]
        backward = [origin, len(graph[origin]), 0, -cost]
        graph[origin].append(forward)
        graph[destination].append(backward)

    for door in range(door_count):
        add_edge(source, first_door + door, 1, 0)
    for key_index in range(key_count):
        add_edge(first_key + key_index, sink, 1, 0)
    for door in range(door_count):
        for key_index in range(key_count):
            key_value = key_start + key_index
            distance = abs(key_value - keys[door])
            cost = (distance + powers[door] - 1) // powers[door]
            add_edge(first_door + door, first_key + key_index, 1, cost)

    potential = [0] * size
    total = 0
    for _ in range(required):
        distance = [INF] * size
        distance[source] = 0
        parent = [None] * size
        heap = [(0, source)]
        while heap:
            current_distance, node = heapq.heappop(heap)
            if current_distance != distance[node]:
                continue
            for edge in graph[node]:
                neighbour, reverse_index, capacity, cost = edge
                if capacity <= 0:
                    continue
                candidate = current_distance + cost + potential[node] - potential[neighbour]
                if candidate < distance[neighbour]:
                    distance[neighbour] = candidate
                    parent[neighbour] = (node, edge)
                    heapq.heappush(heap, (candidate, neighbour))
        if distance[sink] == INF:
            return None
        path_cost = 0
        node = sink
        while node != source:
            previous_node, edge = parent[node]
            path_cost += edge[3]
            edge[2] -= 1
            graph[node][edge[1]][2] += 1
            node = previous_node
        for node in range(size):
            if distance[node] < INF:
                potential[node] += distance[node]
        total += path_cost
    return total


def brute(case):
    door_count, required, keys, powers = case
    key_start = min(keys) - 20
    key_end = max(keys) + 21

    @lru_cache(maxsize=None)
    def solve(door_index, used_keys):
        if len(used_keys) >= required:
            return 0
        if door_index == door_count:
            return INF
        best = INF
        for key_value in range(key_start, key_end):
            if key_value in used_keys:
                continue
            distance = abs(key_value - keys[door_index])
            cost = (distance + powers[door_index] - 1) // powers[door_index]
            best = min(best, cost + solve(door_index + 1, used_keys + (key_value,)))
        best = min(best, solve(door_index + 1, used_keys))
        return best

    return solve(0, ())


def oracle(text):
    tokens = [int(token) for token in text.split()]
    position = 0
    test_count = tokens[position]
    position += 1
    answers = []
    for _ in range(test_count):
        door_count = tokens[position]
        required = tokens[position + 1]
        position += 2
        keys = tokens[position:position + door_count]
        position += door_count
        powers = tokens[position:position + door_count]
        position += door_count
        answers.append(str(min_cost_flow((door_count, required, keys, powers))))
    return "\n".join(answers) + "\n"


SAMPLE = """4
3 2
5 1 3
1 1 1
3 3
1 1 1
2 1 1
4 4
1 1 1 2
1 2 1 1
4 3
1 1 1 2
1 2 1 1
"""
SAMPLE_OUT = """0
2
2
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
SMALL = [
    (1, 1, [5], [2]),
    (2, 2, [7, 7], [1, 1]),
    (3, 3, [1, 1, 1], [1, 1, 1]),
    (3, 2, [5, 1, 3], [1, 1, 1]),
]
for small_case in SMALL:
    assert min_cost_flow(small_case) == brute(small_case)
assert min_cost_flow((1, 1, [5], [2])) == 0


def case_text(case):
    door_count, required, keys, powers = case
    text = f"{door_count} {required}\n"
    text += " ".join(str(value) for value in keys) + "\n"
    text += " ".join(str(value) for value in powers) + "\n"
    return text


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(case_text(case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", SMALL)
    rng = random.Random(20261126)
    wide = (50, 50, [rng.randint(1, 50) for _ in range(50)],
            [rng.randint(1, 5) for _ in range(50)])
    write("3_wide", [wide])
    random_cases = []
    for _ in range(5):
        size = rng.randint(5, 30)
        random_cases.append((size, rng.randint(1, size),
                             [rng.randint(1, 100) for _ in range(size)],
                             [rng.randint(1, 5) for _ in range(size)]))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        size = 30
        io_cases.append((size, size, [rng.randint(1, 30) for _ in range(size)],
                         [rng.randint(1, 5) for _ in range(size)]))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 2, [5, 1, 3], [1, 1, 1]),
                   (3, 3, [1, 1, 1], [2, 1, 1]),
                   (4, 4, [1, 1, 1, 2], [1, 2, 1, 1]),
                   (4, 3, [1, 1, 1, 2], [1, 2, 1, 1])])
build()
