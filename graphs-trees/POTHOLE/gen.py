#!/usr/bin/env python3
import collections
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def solve_case(chamber_count, corridors):
    edge_to = []
    edge_cap = []
    graph = [[] for _ in range(chamber_count + 1)]

    def add_edge(from_node, to_node, capacity):
        graph[from_node].append(len(edge_to))
        edge_to.append(to_node)
        edge_cap.append(capacity)
        graph[to_node].append(len(edge_to))
        edge_to.append(from_node)
        edge_cap.append(0)

    for from_chamber, to_chamber in corridors:
        capacity = 1 if from_chamber == 1 or to_chamber == chamber_count else INF
        add_edge(from_chamber, to_chamber, capacity)

    source = 1
    sink = chamber_count
    total = 0
    while True:
        parent = [-1] * (chamber_count + 1)
        parent_edge = [-1] * (chamber_count + 1)
        parent[source] = -2
        queue = collections.deque([source])
        while queue and parent[sink] == -1:
            node = queue.popleft()
            for edge_index in graph[node]:
                next_node = edge_to[edge_index]
                if edge_cap[edge_index] > 0 and parent[next_node] == -1:
                    parent[next_node] = node
                    parent_edge[next_node] = edge_index
                    queue.append(next_node)
        if parent[sink] == -1:
            break
        pushed = INF
        node = sink
        while node != source:
            pushed = min(pushed, edge_cap[parent_edge[node]])
            node = parent[node]
        node = sink
        while node != source:
            edge_index = parent_edge[node]
            edge_cap[edge_index] -= pushed
            edge_cap[edge_index ^ 1] += pushed
            node = parent[node]
        total += pushed
    return total


def parse_cases(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position])
    position += 1
    cases = []
    for _ in range(case_count):
        chamber_count = int(tokens[position])
        position += 1
        corridors = []
        for from_chamber in range(1, chamber_count):
            corridor_count = int(tokens[position])
            position += 1
            for _ in range(corridor_count):
                to_chamber = int(tokens[position])
                position += 1
                corridors.append((from_chamber, to_chamber))
        cases.append((chamber_count, corridors))
    return cases


def oracle(text):
    return "\n".join(str(solve_case(n, corridors))
                     for n, corridors in parse_cases(text)) + "\n"


def build_input(cases):
    lines = [str(len(cases))]
    for chamber_count, adjacency in cases:
        lines.append(str(chamber_count))
        for chamber in range(1, chamber_count):
            neighbors = adjacency.get(chamber, [])
            lines.append(" ".join([str(len(neighbors))] +
                                  [str(value) for value in neighbors]))
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = build_input(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [(12, {
    1: [3, 4, 2, 5], 2: [8], 3: [9, 7], 4: [6, 11], 5: [8],
    6: [9, 10], 7: [10, 11], 8: [12], 9: [10, 12],
    10: [12], 11: [12],
})]
assert oracle(build_input(SAMPLE)) == "3\n"
assert solve_case(2, [(1, 2)]) == 1
assert solve_case(2, [(1, 2), (1, 2)]) == 2
assert solve_case(5, [(1, 2), (1, 3), (2, 3), (3, 4)]) == 0
assert solve_case(6, [(1, 2), (1, 3), (1, 4), (2, 5), (3, 5),
                      (4, 6), (5, 6)]) == 2


def worked_example():
    chamber_count, adjacency = SAMPLE[0]
    corridors = [(chamber, neighbor)
                 for chamber in range(1, chamber_count)
                 for neighbor in adjacency.get(chamber, [])]
    edge_to = []
    edge_cap = []
    graph = [[] for _ in range(chamber_count + 1)]
    corridor_label = {}

    def add_edge(from_node, to_node, capacity, label=""):
        graph[from_node].append(len(edge_to))
        edge_to.append(to_node)
        edge_cap.append(capacity)
        corridor_label[len(edge_to) - 1] = label
        graph[to_node].append(len(edge_to))
        edge_to.append(from_node)
        edge_cap.append(0)
        corridor_label[len(edge_to) - 1] = ""

    for from_chamber, to_chamber in corridors:
        capacity = 1 if from_chamber == 1 or to_chamber == chamber_count else INF
        label = f"{from_chamber}->{to_chamber}"
        add_edge(from_chamber, to_chamber, capacity, label)

    source = 1
    sink = chamber_count
    total = 0
    lines = []
    while True:
        parent = [-1] * (chamber_count + 1)
        parent_edge = [-1] * (chamber_count + 1)
        parent[source] = -2
        queue = collections.deque([source])
        while queue and parent[sink] == -1:
            node = queue.popleft()
            for edge_index in graph[node]:
                next_node = edge_to[edge_index]
                if edge_cap[edge_index] > 0 and parent[next_node] == -1:
                    parent[next_node] = node
                    parent_edge[next_node] = edge_index
                    queue.append(next_node)
        if parent[sink] == -1:
            break
        path = []
        node = sink
        while node != source:
            path.append(node)
            node = parent[node]
        path.reverse()
        pushed = INF
        node = sink
        while node != source:
            edge_index = parent_edge[node]
            pushed = min(pushed, edge_cap[edge_index])
            node = parent[node]
        node = sink
        while node != source:
            edge_index = parent_edge[node]
            edge_cap[edge_index] -= pushed
            edge_cap[edge_index ^ 1] += pushed
            node = parent[node]
        total += pushed
        route = " -> ".join(str(value) for value in [source] + path)
        lines.append(f"path {len(lines) + 1}: {route}  bottleneck {pushed}")
    lines.append(f"total flow: {total}")
    return "\n".join(lines)


def build():
    write("2_edges", [
        (2, {1: [2]}),
        (2, {1: []}),
        (2, {1: [2, 2]}),
        (5, {1: [2, 3], 2: [3], 3: [4]}),
        (6, {1: [2, 3, 4], 2: [5], 3: [5], 4: [6], 5: [6]}),
        (3, {1: [2], 2: [3, 3]}),
    ])

    full = {chamber: list(range(chamber + 1, 201)) for chamber in range(1, 200)}
    star = {1: list(range(2, 201))}
    for chamber in range(2, 200):
        star[chamber] = [200]
    path = {chamber: [chamber + 1] for chamber in range(1, 200)}
    write("3_wide", [(200, full), (200, star), (200, path)])

    random.seed(2026)
    random_cases = []
    for _ in range(20):
        chamber_count = random.randint(2, 200)
        adjacency = {}
        for chamber in range(1, chamber_count):
            candidates = list(range(chamber + 1, chamber_count + 1))
            size = random.randint(0, len(candidates))
            adjacency[chamber] = random.sample(candidates, size)
        random_cases.append((chamber_count, adjacency))
    write("4_random", random_cases)

    write("5_io", [(2, {1: [2]}) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
print(worked_example())
