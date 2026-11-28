#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BIG_PATH = Path("/tmp/NETADMIN_big.txt")

SAMPLE_INPUT = """2
5 5 4
2 3 4 5
1 2
1 3
2 3
2 4
3 5
8 8 3
4 5 7
1 2
1 8
8 7
1 3
3 6
3 2
2 4
2 5
"""

SAMPLE_CLIENTS = [[2, 3, 4, 5], [4, 5, 7]]
SAMPLE_EDGES = [
    [(1, 2), (1, 3), (2, 3), (2, 4), (3, 5)],
    [(1, 2), (1, 8), (8, 7), (1, 3), (3, 6), (3, 2), (2, 4), (2, 5)],
]

COUNTEREXAMPLE = (
    7,
    [2, 3, 4, 5, 7],
    [(1, 2), (1, 4), (1, 7), (2, 3), (2, 4), (2, 6), (4, 5), (4, 7), (5, 7), (6, 7)],
)


def parse(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    cases = []
    for _ in range(count):
        house_count = int(tokens[cursor]); cursor += 1
        street_count = int(tokens[cursor]); cursor += 1
        client_count = int(tokens[cursor]); cursor += 1
        clients = [int(tokens[cursor + index]) for index in range(client_count)]
        cursor += client_count
        edges = []
        for _ in range(street_count):
            first_house = int(tokens[cursor]); cursor += 1
            second_house = int(tokens[cursor]); cursor += 1
            edges.append((first_house, second_house))
        cases.append((house_count, clients, edges))
    return cases


def capacity_matrix(house_count, clients, edges, capacity):
    cap = [[0] * (house_count + 1) for _ in range(house_count + 1)]
    for client in clients:
        cap[0][client] += 1
    for first_house, second_house in edges:
        cap[first_house][second_house] += capacity
        cap[second_house][first_house] += capacity
    return cap


def edmonds_karp(house_count, clients, edges, capacity, trace=None):
    cap = capacity_matrix(house_count, clients, edges, capacity)
    adjacency = [[] for _ in range(house_count + 1)]
    for client in clients:
        adjacency[0].append(client)
        adjacency[client].append(0)
    for first_house, second_house in edges:
        adjacency[first_house].append(second_house)
        adjacency[second_house].append(first_house)
    flow = 0
    while True:
        parent = [-1] * (house_count + 1)
        parent[0] = 0
        queue = deque([0])
        while queue and parent[1] == -1:
            current = queue.popleft()
            for neighbor in adjacency[current]:
                if cap[current][neighbor] > 0 and parent[neighbor] == -1:
                    parent[neighbor] = current
                    queue.append(neighbor)
                    if neighbor == 1:
                        break
        if parent[1] == -1:
            break
        bottleneck = len(clients)
        node = 1
        while node != 0:
            previous = parent[node]
            bottleneck = min(bottleneck, cap[previous][node])
            node = previous
        if trace is not None:
            path = []
            node = 1
            while node != 0:
                path.append(node)
                node = parent[node]
            path.reverse()
            trace.append(([0] + path, bottleneck))
        node = 1
        while node != 0:
            previous = parent[node]
            cap[previous][node] -= bottleneck
            cap[node][previous] += bottleneck
            node = previous
        flow += bottleneck
    return flow


def brute_min_colors(house_count, clients, edges):
    client_set = set(clients)
    client_total = len(clients)
    best = 0
    for mask in range(1 << house_count):
        if not (mask & 1):
            continue
        inside_clients = sum(1 for client in client_set if mask & (1 << (client - 1)))
        crossing = sum(1 for first_house, second_house in edges
                       if bool(mask & (1 << (first_house - 1)))
                       != bool(mask & (1 << (second_house - 1))))
        if crossing:
            need = -(-(client_total - inside_clients) // crossing)
            best = max(best, need)
    return best


def color_count(house_count, clients, edges, trace=None):
    lower = 0
    upper = len(clients) + 1
    while upper - lower > 1:
        middle = (lower + upper) // 2
        achieved = edmonds_karp(house_count, clients, edges, middle)
        if trace is not None:
            trace.append((middle, achieved, achieved == len(clients)))
        if achieved == len(clients):
            upper = middle
        else:
            lower = middle
    return upper


def oracle(text):
    cases = parse(text)
    return "".join(str(color_count(*case)) + "\n" for case in cases)


def verify():
    assert oracle(SAMPLE_INPUT) == "2\n1\n"
    assert color_count(2, [2], [(1, 2)]) == 1
    assert color_count(3, [2, 3], [(1, 2), (2, 3)]) == 2
    assert color_count(4, [2, 3, 4], [(1, 2), (1, 3), (1, 4)]) == 1
    assert color_count(5, [2, 3, 4, 5], [(1, 2), (2, 3), (3, 4), (4, 5)]) == 4
    assert color_count(*COUNTEREXAMPLE) == 2
    check = random.Random(101)
    for _ in range(250):
        house_count = check.randint(3, 8)
        clients = sorted(check.sample(range(2, house_count + 1),
                                      check.randint(1, house_count - 1)))
        edges = []
        for house in range(2, house_count + 1):
            edges.append((house, check.randint(1, house - 1)))
        for first_house in range(1, house_count + 1):
            for second_house in range(first_house + 1, house_count + 1):
                if check.random() < 0.4:
                    edges.append((first_house, second_house))
        flowed = color_count(house_count, clients, edges)
        cut_bound = brute_min_colors(house_count, clients, edges)
        assert flowed == cut_bound, (house_count, clients, edges, flowed, cut_bound)


def write_pair(name, cases):
    lines = [str(len(cases))]
    for house_count, clients, edges in cases:
        lines.append("%d %d %d" % (house_count, len(edges), len(clients)))
        lines.append(" ".join(str(client) for client in clients))
        for first_house, second_house in edges:
            lines.append("%d %d" % (first_house, second_house))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


def build_edges():
    cases = [
        (2, [2], [(1, 2)]),
        (3, [2, 3], [(1, 2), (2, 3)]),
        (3, [2, 3], [(1, 2), (1, 3), (2, 3)]),
        (4, [2, 3, 4], [(1, 2), (1, 3), (1, 4)]),
        (4, [2, 3, 4], [(1, 2), (2, 3), (3, 4)]),
        (4, [2, 3, 4], [(1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]),
        (5, [2, 3, 4, 5], [(1, 2), (2, 3), (3, 4), (4, 5)]),
        (5, [2, 3, 4, 5], [(1, 2), (1, 3), (2, 4), (3, 5)]),
        (6, [2, 4, 6], [(1, 2), (1, 3), (2, 4), (3, 4), (4, 6)]),
        (7, [3, 5, 7], [(1, 2), (2, 3), (1, 4), (4, 5), (1, 6), (6, 7)]),
        COUNTEREXAMPLE,
        (5, SAMPLE_CLIENTS[0], SAMPLE_EDGES[0]),
        (8, SAMPLE_CLIENTS[1], SAMPLE_EDGES[1]),
    ]
    write_pair("2_edges", cases)


def build_wide():
    house_count = 500
    clients = list(range(2, house_count + 1))
    dense_edges = []
    for first_house in range(1, house_count + 1):
        for offset in range(1, 41):
            second_house = first_house + offset
            if second_house <= house_count:
                dense_edges.append((first_house, second_house))
    bottleneck_edges = [(1, 2)] + [(house, house + 1) for house in range(2, house_count)]
    write_pair("3_wide", [
        (house_count, clients, dense_edges),
        (house_count, clients, bottleneck_edges),
    ])


def build_random():
    rng = random.Random(424242)
    cases = []
    for _ in range(24):
        house_count = rng.randint(10, 120)
        edges = []
        for house in range(2, house_count + 1):
            parent = rng.randint(1, house - 1)
            edges.append((house, parent))
        extra = rng.randint(house_count, 3 * house_count)
        for _ in range(extra):
            first_house = rng.randint(1, house_count)
            second_house = rng.randint(1, house_count)
            if first_house != second_house:
                edges.append((first_house, second_house))
        edges = list(set(edges))
        clients = sorted(rng.sample(range(2, house_count + 1),
                                    rng.randint(1, house_count - 1)))
        cases.append((house_count, clients, edges))
    write_pair("4_random", cases)


def build_io():
    rng = random.Random(777001)
    cases = []
    for _ in range(500):
        house_count = 30
        edges = []
        for house in range(2, house_count + 1):
            edges.append((house, rng.randint(1, house - 1)))
        for _ in range(30):
            first_house = rng.randint(1, house_count)
            second_house = rng.randint(1, house_count)
            if first_house != second_house:
                edges.append((first_house, second_house))
        edges = list(set(edges))
        clients = sorted(rng.sample(range(2, house_count + 1), rng.randint(1, 8)))
        cases.append((house_count, clients, edges))
    write_pair("5_io", cases)


def build_stress():
    lines = ["3"]
    for _ in range(3):
        house_count = 500
        edges = []
        for house in range(2, house_count + 1):
            edges.append((house, (house - 2) // 20 + 1))
        for first_house in range(1, house_count + 1):
            for offset in range(1, 61):
                second_house = first_house + offset
                if second_house <= house_count:
                    edges.append((first_house, second_house))
        clients = list(range(2, house_count + 1))
        lines.append("%d %d %d" % (house_count, len(edges), len(clients)))
        lines.append(" ".join(str(client) for client in clients))
        for first_house, second_house in edges:
            lines.append("%d %d" % (first_house, second_house))
    BIG_PATH.write_text("\n".join(lines) + "\n")


def worked_example():
    trace = []
    answer = color_count(5, SAMPLE_CLIENTS[0], SAMPLE_EDGES[0], trace)
    lines = ["| tested capacity | max flow | serves 4 clients? |",
             "| --- | --- | --- |"]
    for capacity, achieved, feasible in trace:
        lines.append("| %d | %d | %s |" % (capacity, achieved, "yes" if feasible else "no"))
    lines.append("")
    lines.append("smallest feasible capacity = %d, so the answer is %d" % (answer, answer))
    return "\n".join(lines)


def main():
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "--example":
        print(worked_example())
        return
    verify()
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
    assert oracle(SAMPLE_INPUT) == "2\n1\n"
    (ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE_INPUT))
    build_edges()
    build_wide()
    build_random()
    build_io()
    build_stress()


if __name__ == "__main__":
    main()
