#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**15


def parse_input(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    cases = []
    for _ in range(case_count):
        place_count = int(tokens[cursor]); cursor += 1
        street_count = int(tokens[cursor]); cursor += 1
        edges = []
        for _ in range(street_count):
            source = int(tokens[cursor]); cursor += 1
            target = int(tokens[cursor]); cursor += 1
            length = int(tokens[cursor]); cursor += 1
            if source != target:
                edges.append((source, target, length))
        cases.append((place_count, edges))
    return cases


def brute_cost(place_count, edges):
    matrix = [[INF] * (place_count + 1) for _ in range(place_count + 1)]
    for source, target, length in edges:
        matrix[source][target] = min(matrix[source][target], length)
    full_mask = (1 << place_count) - 1
    dp = [INF] * (full_mask + 1)
    dp[0] = 0
    for mask in range(full_mask + 1):
        next_row = mask.bit_count() + 1
        if next_row > place_count or dp[mask] == INF:
            continue
        row = matrix[next_row]
        for target in range(1, place_count + 1):
            if mask & (1 << (target - 1)) == 0 and row[target] < INF:
                new_mask = mask | (1 << (target - 1))
                candidate = dp[mask] + row[target]
                if candidate < dp[new_mask]:
                    dp[new_mask] = candidate
    return dp[full_mask]


def flow_cost(place_count, edges):
    source = 0
    column_offset = place_count
    sink = 2 * place_count + 1
    node_count = sink + 1
    graph = [[] for _ in range(node_count)]

    def add_edge(tail, head, capacity, cost):
        graph[tail].append([head, len(graph[head]), capacity, cost])
        graph[head].append([tail, len(graph[tail]) - 1, 0, -cost])

    for row in range(1, place_count + 1):
        add_edge(source, row, 1, 0)
    for street_from, street_to, length in edges:
        add_edge(street_from, column_offset + street_to, 1, length)
    for column in range(place_count + 1, sink):
        add_edge(column, sink, 1, 0)

    potential = [0] * node_count
    total_cost = 0
    for _ in range(place_count):
        distance = [INF] * node_count
        distance[source] = 0
        parent_node = [-1] * node_count
        parent_edge = [-1] * node_count
        queue = [(0, source)]
        while queue:
            current_distance, node = heapq.heappop(queue)
            if current_distance != distance[node]:
                continue
            for edge_index, edge in enumerate(graph[node]):
                head, reverse_index, capacity, cost = edge
                if capacity == 0:
                    continue
                new_distance = current_distance + cost + potential[node] - potential[head]
                if new_distance < distance[head]:
                    distance[head] = new_distance
                    parent_node[head] = node
                    parent_edge[head] = edge_index
                    heapq.heappush(queue, (new_distance, head))
        if distance[sink] == INF:
            raise ValueError("input has no tour cover")
        for node in range(node_count):
            if distance[node] < INF:
                potential[node] += distance[node]
        node = sink
        while node != source:
            previous = parent_node[node]
            edge_index = parent_edge[node]
            edge = graph[previous][edge_index]
            edge[2] -= 1
            graph[node][edge[1]][2] += 1
            total_cost += edge[3]
            node = previous
    return total_cost


def oracle(text):
    answers = [str(flow_cost(place_count, edges)) for place_count, edges in parse_input(text)]
    return "\n".join(answers) + "\n"


def write_case(name, cases):
    lines = [str(len(cases))]
    for place_count, edges in cases:
        lines.append(f"{place_count} {len(edges)}")
        lines.extend(f"{source} {target} {length}" for source, target, length in edges)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def cycle_edges(place_count, rng=None, low=1, high=10000):
    order = list(range(1, place_count + 1))
    if rng is not None:
        rng.shuffle(order)
    edges = []
    for index in range(place_count):
        length = rng.randint(low, high) if rng is not None else 1
        edges.append((order[index], order[(index + 1) % place_count], length))
    return edges


def random_case(place_count, density, rng):
    edges = cycle_edges(place_count, rng)
    seen = {(source, target) for source, target, _ in edges}
    for _ in range(density * place_count):
        source = rng.randint(1, place_count)
        target = rng.randint(1, place_count)
        if source == target or (source, target) in seen:
            continue
        seen.add((source, target))
        edges.append((source, target, rng.randint(1, 10000)))
    return place_count, edges


SAMPLE = """2
6 9
1 2 5
2 3 5
3 1 10
3 4 12
4 1 8
4 6 11
5 4 7
5 6 9
6 5 4
5 8
1 2 4
2 1 7
1 3 10
3 2 10
3 4 10
4 5 10
5 3 10
5 4 3
"""

assert oracle(SAMPLE) == "42\n40\n"
assert flow_cost(3, [(1, 2, 1), (2, 3, 2), (3, 1, 3)]) == 6
assert flow_cost(4, [(1, 2, 1), (2, 1, 2), (3, 4, 3), (4, 3, 4)]) == 10
assert flow_cost(20, [(u, v, 7) for u in range(1, 21)
                      for v in range(1, 21) if u != v]) == 140
checker = random.Random(913)
for _ in range(40):
    size = checker.randint(2, 7)
    trial = random_case(size, 2, checker)
    assert flow_cost(size, trial[1]) == brute_cost(size, trial[1])

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", parse_input(SAMPLE))

write_case("2_edges", [
    (2, [(1, 2, 5), (2, 1, 7)]),
    (2, [(1, 1, 1), (1, 2, 3), (1, 2, 2), (2, 1, 4)]),
    (3, [(1, 2, 1), (2, 3, 2), (3, 1, 3)]),
    (4, [(1, 2, 1), (2, 1, 2), (3, 4, 3), (4, 3, 4)]),
    (4, [(1, 2, 10000), (2, 1, 10000), (3, 4, 10000), (4, 3, 10000)]),
    (5, [(1, 2, 9), (2, 3, 9), (3, 4, 9), (4, 5, 9), (5, 1, 9),
         (1, 3, 2), (3, 1, 2), (2, 4, 2), (4, 2, 2)]),
    (200, cycle_edges(200)),
    (2, [(1, 2, 1), (2, 1, 1)]),
])

wide_rng = random.Random(3701)
write_case("3_wide", [
    (200, [(u, v, 1) for u in range(1, 201) for v in range(1, 201) if u != v]),
    (200, [(u, v, 10000) for u in range(1, 201) for v in range(1, 201) if u != v]),
    random_case(200, 100, wide_rng),
    random_case(200, 3, wide_rng),
])

random_rng = random.Random(20261125)
write_case("4_random", [random_case(200, random_rng.choice([5, 20, 60, 100]), random_rng)
                        for _ in range(15)])

io_rng = random.Random(424242)
write_case("5_io", [random_case(200, 20, io_rng) for _ in range(15)])

print("generated five test pairs")
