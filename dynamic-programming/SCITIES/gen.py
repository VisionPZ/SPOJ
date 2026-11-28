#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def best_edges(seller_count, buyer_count, edges):
    keep = {}
    for seller, buyer, goods in edges:
        if 1 <= seller <= seller_count and 1 <= buyer <= buyer_count:
            key = (seller, buyer)
            if keep.get(key, -1) < goods:
                keep[key] = goods
    return keep


def flow_oracle(seller_count, buyer_count, edges):
    keep = best_edges(seller_count, buyer_count, edges)
    source = 0
    buyer_base = 1 + seller_count
    sink = buyer_base + buyer_count
    graph = [[] for _ in range(sink + 1)]

    def add_edge(start, end, capacity, cost):
        forward = [end, capacity, cost, len(graph[end])]
        backward = [start, 0, -cost, len(graph[start])]
        graph[start].append(forward)
        graph[end].append(backward)

    for seller in range(seller_count):
        add_edge(source, 1 + seller, 1, 0)
    for buyer in range(buyer_count):
        add_edge(buyer_base + buyer, sink, 1, 0)
    for (seller, buyer), goods in keep.items():
        add_edge(1 + seller - 1, buyer_base + buyer - 1, 1, -goods)

    total = 0
    while True:
        distance = [10 ** 9] * len(graph)
        queued = [False] * len(graph)
        previous_node = [-1] * len(graph)
        previous_edge = [-1] * len(graph)
        distance[source] = 0
        queue = [source]
        queued[source] = True
        while queue:
            node = queue.pop(0)
            queued[node] = False
            for edge_index, edge in enumerate(graph[node]):
                end, capacity, cost, _ = edge
                if capacity > 0 and distance[node] + cost < distance[end]:
                    distance[end] = distance[node] + cost
                    previous_node[end] = node
                    previous_edge[end] = edge_index
                    if not queued[end]:
                        queued[end] = True
                        queue.append(end)
        if distance[sink] >= 0 or previous_node[sink] == -1:
            break
        node = sink
        while node != source:
            parent = previous_node[node]
            edge_index = previous_edge[node]
            edge = graph[parent][edge_index]
            edge[1] -= 1
            graph[node][edge[3]][1] += 1
            node = parent
        total += distance[sink]
    return -total


def brute_oracle(seller_count, buyer_count, edges):
    weights = [[0] * buyer_count for _ in range(seller_count)]
    for (seller, buyer), goods in best_edges(seller_count, buyer_count, edges).items():
        weights[seller - 1][buyer - 1] = goods
    states = [-1] * (1 << buyer_count)
    states[0] = 0
    for seller in range(seller_count):
        updated = states[:]
        for mask in range(1 << buyer_count):
            if states[mask] < 0:
                continue
            for buyer in range(buyer_count):
                if not (mask >> buyer) & 1 and weights[seller][buyer] > 0:
                    new_mask = mask | (1 << buyer)
                    value = states[mask] + weights[seller][buyer]
                    if value > updated[new_mask]:
                        updated[new_mask] = value
        states = updated
    return max(states)


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        seller_count = int(tokens[cursor]); cursor += 1
        buyer_count = int(tokens[cursor]); cursor += 1
        edges = []
        while True:
            seller = int(tokens[cursor]); cursor += 1
            buyer = int(tokens[cursor]); cursor += 1
            goods = int(tokens[cursor]); cursor += 1
            if seller == 0 and buyer == 0 and goods == 0:
                break
            edges.append((seller, buyer, goods))
        answers.append(flow_oracle(seller_count, buyer_count, edges))
    return "".join(f"{answer}\n" for answer in answers)


def render(cases):
    lines = [str(len(cases))]
    for seller_count, buyer_count, edges in cases:
        lines.append(f"{seller_count} {buyer_count}")
        for seller, buyer, goods in edges:
            lines.append(f"{seller} {buyer} {goods}")
        lines.append("0 0 0")
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [
    (3, 2, [(1, 1, 10), (2, 1, 19), (2, 2, 11), (3, 2, 1)]),
    (4, 4, [(1, 1, 6), (1, 2, 6), (2, 1, 8), (2, 3, 9),
            (2, 4, 8), (3, 2, 8), (4, 3, 7)]),
    (3, 2, [(1, 1, 10), (2, 1, 21), (2, 2, 11), (3, 2, 1)]),
]

assert oracle(render(SAMPLE)) == "21\n29\n22\n"
assert flow_oracle(2, 2, [(1, 1, 100), (1, 2, 1), (2, 1, 1)]) == 100
assert flow_oracle(1, 1, []) == 0
assert flow_oracle(3, 3, [(1, 1, 5), (2, 2, 7), (3, 3, 9)]) == 21
assert flow_oracle(2, 3, [(1, 2, 4), (2, 2, 6), (2, 3, 3)]) == 7

check_rng = random.Random(77)
for _ in range(300):
    small_sellers = check_rng.randint(1, 5)
    small_buyers = check_rng.randint(1, 5)
    small_edges = [
        (check_rng.randint(1, small_sellers), check_rng.randint(1, small_buyers),
         check_rng.randint(1, 20))
        for _ in range(check_rng.randint(0, 12))
    ]
    assert flow_oracle(small_sellers, small_buyers, small_edges) == \
        brute_oracle(small_sellers, small_buyers, small_edges)


def build():
    edges = [
        (1, 1, [(1, 1, 7)]),
        (1, 1, []),
        (2, 2, [(1, 1, 100), (1, 2, 1), (2, 1, 1)]),
        (2, 3, [(2, 3, 42)]),
        (3, 3, [(1, 1, 5), (1, 2, 5), (2, 1, 5), (2, 2, 5), (3, 3, 7)]),
        (100, 100, []),
    ]
    write("2_edges", edges)

    rng = random.Random(1234)
    dense = [(seller, buyer, rng.randint(1, 100))
             for seller in range(1, 101) for buyer in range(1, 101)]
    full = [(seller, buyer, 100)
            for seller in range(1, 101) for buyer in range(1, 101)]
    wide = [
        (100, 100, dense),
        (100, 100, full),
        (100, 1, [(seller, 1, rng.randint(1, 100)) for seller in range(1, 101)]),
        (1, 100, [(1, buyer, rng.randint(1, 100)) for buyer in range(1, 101)]),
    ]
    write("3_wide", wide)

    rng = random.Random(2026)
    random_cases = []
    for _ in range(100):
        seller_count = rng.randint(1, 100)
        buyer_count = rng.randint(1, 100)
        edge_list = [
            (rng.randint(1, seller_count), rng.randint(1, buyer_count),
             rng.randint(1, 100))
            for _ in range(rng.randint(0, 400))
        ]
        random_cases.append((seller_count, buyer_count, edge_list))
    write("4_random", random_cases)

    rng = random.Random(90210)
    io_cases = []
    for _ in range(1000):
        seller_count = rng.randint(1, 10)
        buyer_count = rng.randint(1, 10)
        edge_list = [
            (rng.randint(1, seller_count), rng.randint(1, buyer_count),
             rng.randint(1, 100))
            for _ in range(rng.randint(0, 10))
        ]
        io_cases.append((seller_count, buyer_count, edge_list))
    write("5_io", io_cases)


def worked_example():
    seller_count, buyer_count, edges = SAMPLE[0]
    matrix_size = max(seller_count, buyer_count)
    keep = best_edges(seller_count, buyer_count, edges)
    print(f"sellers {seller_count} buyers {buyer_count} padded size {matrix_size}")
    for seller in range(1, matrix_size + 1):
        cells = []
        for buyer in range(1, matrix_size + 1):
            cells.append(f"{-keep.get((seller, buyer), 0):4d}")
        print(f"row {seller}: {' '.join(cells)}")
    print(f"best total goods {flow_oracle(seller_count, buyer_count, edges)}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
worked_example()
