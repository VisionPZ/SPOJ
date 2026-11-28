#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**18


def shortest_total(node_count, outgoing):
    distance = [INF] * (node_count + 1)
    distance[1] = 0
    queue = [(0, 1)]
    while queue:
        cost, node = heapq.heappop(queue)
        if cost != distance[node]:
            continue
        for target, price in outgoing[node]:
            new_cost = cost + price
            if new_cost < distance[target]:
                distance[target] = new_cost
                heapq.heappush(queue, (new_cost, target))
    return sum(distance[1:])


def oracle(case_text):
    tokens = case_text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    results = []
    for _ in range(case_count):
        node_count = int(tokens[cursor]); cursor += 1
        edge_count = int(tokens[cursor]); cursor += 1
        outgoing = [[] for _ in range(node_count + 1)]
        incoming = [[] for _ in range(node_count + 1)]
        for _ in range(edge_count):
            origin = int(tokens[cursor]); cursor += 1
            target = int(tokens[cursor]); cursor += 1
            price = int(tokens[cursor]); cursor += 1
            outgoing[origin].append((target, price))
            incoming[target].append((origin, price))
        results.append(str(shortest_total(node_count, outgoing) +
                           shortest_total(node_count, incoming)))
    return "\n".join(results) + "\n" if results else ""


def format_case(edges):
    if not edges:
        return ""
    node_count, edge_list = edges
    parts = [f"{node_count} {len(edge_list)}"]
    for origin, target, price in edge_list:
        parts.append(f"{origin} {target} {price}")
    return "\n".join(parts) + "\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_IN = """2
2 2
1 2 13
2 1 33
4 6
1 2 10
2 1 60
1 3 20
3 4 10
2 4 5
4 1 50
"""

assert oracle(SAMPLE_IN) == "46\n210\n"


def build_edges():
    random.seed(271828)

    def chain(count):
        edges = []
        for node in range(1, count):
            edges.append((node, node + 1, random.randint(1, 50)))
            edges.append((node + 1, node, random.randint(1, 50)))
        return (count, edges)

    def star(count):
        edges = []
        for node in range(2, count + 1):
            edges.append((1, node, random.randint(1, 30)))
            edges.append((node, 1, random.randint(1, 30)))
        return (count, edges)

    edge_cases = []
    edge_cases.append((1, [(1, 1, 7)]))
    edge_cases.append((2, [(1, 2, 5), (2, 1, 9)]))
    edge_cases.append((3, [(1, 2, 4), (2, 3, 6), (3, 1, 8)]))
    edge_cases.append((5, [(1, 2, 3), (1, 2, 1), (2, 1, 2), (2, 3, 4),
                            (3, 4, 5), (4, 5, 6), (5, 1, 7), (5, 3, 2)]))
    write("2_edges", str(len(edge_cases)) + "\n" +
          "".join(format_case(edges) for edges in edge_cases))

    wide = [chain(3000), star(3000), chain(2500)]
    write("3_wide", str(len(wide)) + "\n" +
          "".join(format_case(edges) for edges in wide))

    random_cases = []
    for _ in range(10):
        count = random.randint(2, 400)
        edges = chain(count)
        extra = random.randint(100, 800)
        for _ in range(extra):
            origin = random.randint(1, count)
            target = random.randint(1, count)
            edges[1].append((origin, target, random.randint(1, 100)))
        random_cases.append(edges)
    write("4_random", str(len(random_cases)) + "\n" +
          "".join(format_case(edges) for edges in random_cases))

    io_cases = [(2, [(1, 2, i % 17 + 1), (2, 1, i % 23 + 1)])
                for i in range(20000)]
    write("5_io", str(len(io_cases)) + "\n" +
          "".join(format_case(edges) for edges in io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_IN)
build_edges()
