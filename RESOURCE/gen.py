#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle_case(row_count, column_count, ticket_cost, heights):
    cell_count = row_count * column_count
    node_count = 2 * cell_count + 2
    source = 0
    sink = node_count - 1
    graph = [[] for _ in range(node_count)]

    def add_edge(start, end, capacity, cost):
        forward = len(graph[start])
        graph[start].append([end, len(graph[end]), capacity, cost])
        graph[end].append([start, forward, 0, -cost])

    for cell in range(cell_count):
        add_edge(source, 1 + cell, 1, 0)
        add_edge(1 + cell_count + cell, sink, 1, 0)
    for row in range(row_count):
        for column in range(column_count):
            cell = row * column_count + column
            for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                neighbor_row = row + delta_row
                neighbor_column = column + delta_column
                if not (0 <= neighbor_row < row_count and 0 <= neighbor_column < column_count):
                    continue
                neighbor = neighbor_row * column_count + neighbor_column
                if heights[neighbor] < heights[cell]:
                    add_edge(1 + cell, 1 + cell_count + neighbor, 1, heights[cell] - heights[neighbor])
    potential = [0] * node_count
    total_flow = 0
    total_cost = 0
    while True:
        distance = [INF] * node_count
        distance[source] = 0
        previous_node = [-1] * node_count
        previous_edge = [-1] * node_count
        queue = [(0, source)]
        while queue:
            current_distance, current = heapq.heappop(queue)
            if current_distance != distance[current]:
                continue
            for edge_index, edge in enumerate(graph[current]):
                end, _, capacity, cost = edge
                if capacity <= 0:
                    continue
                relaxed = current_distance + cost + potential[current] - potential[end]
                if relaxed < distance[end]:
                    distance[end] = relaxed
                    previous_node[end] = current
                    previous_edge[end] = edge_index
                    heapq.heappush(queue, (relaxed, end))
        if previous_node[sink] == -1:
            break
        for node in range(node_count):
            if distance[node] < INF:
                potential[node] += distance[node]
        walk = sink
        while walk != source:
            parent = previous_node[walk]
            edge_index = previous_edge[walk]
            graph[parent][edge_index][2] -= 1
            graph[walk][graph[parent][edge_index][1]][2] += 1
            total_cost += graph[parent][edge_index][3]
            walk = parent
        total_flow += 1
    ride_count = cell_count - total_flow - 1
    return ride_count * ticket_cost, total_cost


def brute_case(row_count, column_count, ticket_cost, heights):
    cell_count = row_count * column_count
    edges = []
    for row in range(row_count):
        for column in range(column_count):
            cell = row * column_count + column
            for delta_row, delta_column in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                neighbor_row = row + delta_row
                neighbor_column = column + delta_column
                if not (0 <= neighbor_row < row_count and 0 <= neighbor_column < column_count):
                    continue
                neighbor = neighbor_row * column_count + neighbor_column
                if heights[neighbor] < heights[cell]:
                    edges.append((cell, neighbor, heights[cell] - heights[neighbor]))
    best_flow = -1
    best_cost = INF

    def walk(edge_index, used_out, used_in, flow, cost):
        nonlocal best_flow, best_cost
        if edge_index == len(edges):
            if flow > best_flow or (flow == best_flow and cost < best_cost):
                best_flow = flow
                best_cost = cost
            return
        walk(edge_index + 1, used_out, used_in, flow, cost)
        start, end, edge_cost = edges[edge_index]
        if start not in used_out and end not in used_in:
            walk(edge_index + 1, used_out | {start}, used_in | {end}, flow + 1, cost + edge_cost)

    walk(0, set(), set(), 0, 0)
    return (cell_count - best_flow - 1) * ticket_cost, best_cost


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    lines = []
    while True:
        row_count = tokens[pos]
        column_count = tokens[pos + 1]
        ticket_cost = tokens[pos + 2]
        pos += 3
        if row_count == 0 and column_count == 0 and ticket_cost == 0:
            break
        cell_count = row_count * column_count
        heights = tokens[pos:pos + cell_count]
        pos += cell_count
        cost, effort = oracle_case(row_count, column_count, ticket_cost, heights)
        lines.append(f"{cost} {effort}")
    return "\n".join(lines) + "\n" if lines else ""


SAMPLE = "2 2 1\n1 2\n4 3\n3 3 7\n1 2 1\n4 5 3\n1 2 1\n0 0 0\n"
SAMPLE_OUT = "0 3\n21 8\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(1, 1, 5, [42]) == (0, 0)
assert oracle_case(1, 3, 4, [3, 2, 1]) == (0, 2)
assert oracle_case(1, 3, 4, [3, 1, 2]) == (4, 1)
assert oracle_case(2, 2, 9, [5, 5, 5, 5]) == (27, 0)

cross_rng = random.Random(4242)
for _ in range(60):
    row_cross = cross_rng.randint(1, 3)
    column_cross = cross_rng.randint(1, 3)
    heights_cross = [cross_rng.randint(0, 8) for _ in range(row_cross * column_cross)]
    ticket_cross = cross_rng.randint(1, 6)
    assert oracle_case(row_cross, column_cross, ticket_cross, heights_cross) == brute_case(
        row_cross, column_cross, ticket_cross, heights_cross)


def write_case(name, cases):
    text = ""
    for row_count, column_count, ticket_cost, heights in cases:
        text += f"{row_count} {column_count} {ticket_cost}\n"
        for row in range(row_count):
            start = row * column_count
            text += " ".join(str(value) for value in heights[start:start + column_count]) + "\n"
    text += "0 0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        (1, 1, 5, [42]),
        (1, 3, 4, [3, 2, 1]),
        (1, 3, 4, [3, 1, 2]),
        (2, 2, 9, [5, 5, 5, 5]),
        (2, 2, 1, [100, 1, 50, 2]),
    ])
    rng = random.Random(20261126)
    write_case("3_wide", [(15, 15, 13, [rng.randint(0, 100) for _ in range(225)])])
    random_cases = []
    for _ in range(10):
        rows = rng.randint(1, 8)
        columns = rng.randint(1, 8)
        random_cases.append((rows, columns, rng.randint(1, 15),
                             [rng.randint(0, 100) for _ in range(rows * columns)]))
    write_case("4_random", random_cases)
    io_cases = []
    for _ in range(30000):
        rows = rng.randint(1, 3)
        columns = rng.randint(1, 3)
        io_cases.append((rows, columns, rng.randint(1, 15),
                         [rng.randint(0, 100) for _ in range(rows * columns)]))
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [
    (2, 2, 1, [1, 2, 4, 3]),
    (3, 3, 7, [1, 2, 1, 4, 5, 3, 1, 2, 1]),
])
build()
