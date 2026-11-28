#!/usr/bin/env python3
import random
from collections import Counter, deque
from itertools import permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle(cards, edges):
    adjacency = {}

    def add_edge(start, finish, capacity, cost):
        forward = adjacency.setdefault(start, [])
        backward = adjacency.setdefault(finish, [])
        forward.append([finish, capacity, cost, len(backward)])
        backward.append([start, 0, -cost, len(forward) - 1])

    source = -1
    sink = -2
    for label, amount in Counter(cards).items():
        add_edge(source, label, amount, 0)
    for target in range(1, len(cards) + 1):
        add_edge(target, sink, 1, 0)
    for left, right in edges:
        add_edge(left, right, INF, 1)
        add_edge(right, left, INF, 1)

    total_cost = 0
    remaining = len(cards)
    while remaining > 0:
        distance = {source: 0}
        previous = {}
        queued = {source}
        queue = deque([source])
        while queue:
            node = queue.popleft()
            queued.discard(node)
            for edge_index, edge in enumerate(adjacency.get(node, [])):
                neighbor, capacity, cost, _ = edge
                if capacity <= 0:
                    continue
                candidate = distance[node] + cost
                if candidate < distance.get(neighbor, INF):
                    distance[neighbor] = candidate
                    previous[neighbor] = (node, edge_index)
                    if neighbor not in queued:
                        queued.add(neighbor)
                        queue.append(neighbor)
        if sink not in distance:
            return None
        flow = remaining
        cursor = sink
        while cursor != source:
            parent, edge_index = previous[cursor]
            flow = min(flow, adjacency[parent][edge_index][1])
            cursor = parent
        cursor = sink
        while cursor != source:
            parent, edge_index = previous[cursor]
            edge = adjacency[parent][edge_index]
            edge[1] -= flow
            adjacency[cursor][edge[3]][1] += flow
            cursor = parent
        total_cost += flow * distance[sink]
        remaining -= flow
    return total_cost


def brute(cards, edges):
    labels = set(cards) | set(range(1, len(cards) + 1))
    for left, right in edges:
        labels.add(left)
        labels.add(right)
    nodes = sorted(labels)
    index = {label: position for position, label in enumerate(nodes)}
    size = len(nodes)
    distance = [[INF] * size for _ in range(size)]
    for position in range(size):
        distance[position][position] = 0
    for left, right in edges:
        first = index[left]
        second = index[right]
        distance[first][second] = 1
        distance[second][first] = 1
    for middle in range(size):
        for start in range(size):
            for finish in range(size):
                candidate = distance[start][middle] + distance[middle][finish]
                if distance[start][finish] > candidate:
                    distance[start][finish] = candidate
    best = INF
    for order in permutations(range(len(cards))):
        cost = 0
        for card_index, target in enumerate(order):
            cost += distance[index[cards[card_index]]][index[target + 1]]
        best = min(best, cost)
    return best


assert oracle([1, 2, 2, 2], [(2, 3), (3, 4)]) == 3
assert brute([1, 2, 2, 2], [(2, 3), (3, 4)]) == 3
assert oracle([1, 1, 1, 1], [(1, 2), (2, 3), (3, 4)]) == 6
assert brute([1, 1, 1, 1], [(1, 2), (2, 3), (3, 4)]) == 6

checker = random.Random(731)
for trial in range(120):
    card_total = checker.randint(2, 6)
    sample_cards = [checker.randint(1, 9) for _ in range(card_total)]
    sample_nodes = sorted(set(sample_cards) | set(range(1, card_total + 1)))
    sample_edges = list(zip(sample_nodes, sample_nodes[1:]))
    for _ in range(checker.randint(0, 4)):
        sample_edges.append((checker.randint(1, 9), checker.randint(1, 9)))
    assert oracle(sample_cards, sample_edges) == brute(sample_cards, sample_edges)


def write(name, cases):
    input_parts = [str(len(cases)) + "\n"]
    answer_parts = []
    for cards, edges in cases:
        input_parts.append(f"{len(cards)}\n")
        input_parts.extend(f"{card}\n" for card in cards)
        input_parts.append(f"{len(edges)}\n")
        input_parts.extend(f"{left} {right}\n" for left, right in edges)
        input_parts.append("\n")
        answer_parts.append(f"{oracle(cards, edges)}\n")
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / f"{name}.txt").write_text("".join(input_parts))
    (ROOT / "out" / f"{name}.out").write_text("".join(answer_parts))


def make_case(rng, card_total, label_max, extra_edges):
    cards = [rng.randint(1, label_max) for _ in range(card_total)]
    used = sorted(set(cards) | set(range(1, card_total + 1)))
    edges = list(zip(used, used[1:]))
    for _ in range(extra_edges):
        left = rng.randint(1, label_max)
        right = rng.randint(1, label_max)
        if left != right:
            edges.append((left, right))
    rng.shuffle(edges)
    return cards, edges


SAMPLE = ([1, 2, 2, 2], [(2, 3), (3, 4)])
write("1_sample", [SAMPLE])

write("2_edges", [
    ([1, 2, 3, 4, 5], [(1, 5)]),
    ([2, 2], [(1, 2)]),
    ([99999, 99999], [(99999, 5), (5, 1), (1, 2)]),
    ([1, 1, 1, 1], [(1, 2), (2, 3), (3, 4)]),
    ([1, 2, 3], []),
    ([3, 3, 3], [(1, 2), (2, 3)]),
    ([500, 499, 498], [(498, 499), (499, 500), (500, 1), (1, 2), (2, 3)]),
])

wide_rng = random.Random(4812)
write("3_wide", [make_case(wide_rng, 500, 99999, 3000) for _ in range(3)])

random_rng = random.Random(20261125)
write("4_random", [make_case(random_rng, random_rng.randint(2, 80), 9999, 200)
                   for _ in range(10)])

io_rng = random.Random(99)
write("5_io", [make_case(io_rng, 500, 99999, 2000) for _ in range(10)])

print("generated five test pairs")
