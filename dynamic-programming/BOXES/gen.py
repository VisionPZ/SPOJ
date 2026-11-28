#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE_INPUT = "1\n12\n0 0 2 4 3 1 0 0 0 0 0 1\n"


def min_cost_flow(ball_counts):
    box_count = len(ball_counts)
    ball_total = sum(ball_counts)
    if ball_total == 0:
        return 0
    source = box_count
    sink = box_count + 1
    node_count = box_count + 2
    graph = [[] for _ in range(node_count)]

    def add_edge(start, end, capacity, cost):
        forward = [end, capacity, cost, len(graph[end])]
        backward = [start, 0, -cost, len(graph[start])]
        graph[start].append(forward)
        graph[end].append(backward)

    for box_index in range(box_count):
        if ball_counts[box_index] > 0:
            add_edge(source, box_index, ball_counts[box_index], 0)
        add_edge(box_index, sink, 1, 0)
        if box_count > 1:
            add_edge(box_index, (box_index + 1) % box_count, ball_total, 1)
            add_edge((box_index + 1) % box_count, box_index, ball_total, 1)

    total_cost = 0
    for _ in range(ball_total):
        distance = [10**18] * node_count
        previous_node = [-1] * node_count
        previous_edge = [-1] * node_count
        in_queue = [False] * node_count
        distance[source] = 0
        queue = deque([source])
        in_queue[source] = True
        while queue:
            current = queue.popleft()
            in_queue[current] = False
            for edge_index, edge in enumerate(graph[current]):
                target, capacity, cost, _ = edge
                if capacity > 0 and distance[current] + cost < distance[target]:
                    distance[target] = distance[current] + cost
                    previous_node[target] = current
                    previous_edge[target] = edge_index
                    if not in_queue[target]:
                        in_queue[target] = True
                        queue.append(target)
        if previous_node[sink] < 0:
            raise ValueError("no augmenting path")
        total_cost += distance[sink]
        node = sink
        while node != source:
            parent = previous_node[node]
            edge = graph[parent][previous_edge[node]]
            edge[1] -= 1
            graph[node][edge[3]][1] += 1
            node = parent
    return total_cost


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        box_count = int(tokens[cursor])
        cursor += 1
        ball_counts = [int(token) for token in tokens[cursor:cursor + box_count]]
        cursor += box_count
        answers.append(str(min_cost_flow(ball_counts)))
    return "\n".join(answers) + "\n"


def brute_force(ball_counts):
    box_count = len(ball_counts)
    balls = []
    for box_index, count in enumerate(ball_counts):
        balls.extend([box_index] * count)
    if not balls:
        return 0
    infinity = 1 << 30
    states = {0: 0}
    for start in balls:
        following = {}
        for used, cost in states.items():
            for target in range(box_count):
                if (used >> target) & 1:
                    continue
                direct = abs(start - target)
                step = min(direct, box_count - direct)
                candidate = cost + step
                updated = used | (1 << target)
                if following.get(updated, infinity) > candidate:
                    following[updated] = candidate
        states = following
    return min(states.values())


def write_case(name, cases):
    lines = [str(len(cases))]
    for ball_counts in cases:
        lines.append(str(len(ball_counts)))
        lines.append(" ".join(str(count) for count in ball_counts))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == "19\n"
assert min_cost_flow([0, 0, 0, 0, 0]) == 0
assert min_cost_flow([1, 1, 1, 1]) == 0
assert min_cost_flow([100] + [0] * 99) == 2500
check_rng = random.Random(5150)
for _ in range(60):
    size = check_rng.randint(1, 7)
    counts = [check_rng.randint(0, 3) for _ in range(size)]
    if sum(counts) > size:
        continue
    assert min_cost_flow(counts) == brute_force(counts)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write_case("1_sample", [[0, 0, 2, 4, 3, 1, 0, 0, 0, 0, 0, 1]])

write_case("2_edges", [
    [0], [1], [0, 0], [2, 0], [0, 2], [1, 1],
    [3, 0, 0], [0, 0, 3], [0, 2, 1], [1, 0, 2],
    [0] * 12, [1] * 12, [12] + [0] * 11,
    [0] * 20 + [1], [1] + [0] * 19, [0] * 11 + [2],
])

write_case("3_wide", [
    [1000] + [0] * 999,
    [1] * 1000,
    [0] * 1000,
    [500] + [0] * 999,
    [0] * 999 + [1000],
    [1, 0] * 500,
    [0, 1] * 500,
    [2] * 500 + [0] * 500,
])

random_gen = random.Random(20261125)
random_cases = []
for _ in range(20):
    size = 1000
    remaining = size
    counts = []
    for index in range(size - 1):
        count = random_gen.randint(0, min(4, remaining))
        counts.append(count)
        remaining -= count
    counts.append(remaining)
    random_gen.shuffle(counts)
    random_cases.append(counts)
write_case("4_random", random_cases)

write_case("5_io", [
    [1000] + [0] * 999,
    [999] + [0] * 999,
    [998] + [0] * 999,
    [997] + [0] * 999,
    [996] + [0] * 999,
    [995] + [0] * 999,
    [994] + [0] * 999,
    [993] + [0] * 999,
    [992] + [0] * 999,
    [991] + [0] * 999,
    [990] + [0] * 999,
    [989] + [0] * 999,
    [988] + [0] * 999,
    [987] + [0] * 999,
    [986] + [0] * 999,
    [985] + [0] * 999,
    [984] + [0] * 999,
    [983] + [0] * 999,
    [982] + [0] * 999,
    [981] + [0] * 999,
])

print("generated five test pairs")
