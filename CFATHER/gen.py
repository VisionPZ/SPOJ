#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


class Dinic:
    def __init__(self, node_total):
        self.edges = [[] for _ in range(node_total)]

    def add_edge(self, source, target, capacity):
        forward = [target, capacity, len(self.edges[target])]
        backward = [source, 0, len(self.edges[source])]
        self.edges[source].append(forward)
        self.edges[target].append(backward)

    def max_flow(self, source, sink):
        total = 0
        while True:
            level = [-1] * len(self.edges)
            level[source] = 0
            queue = [source]
            for node in queue:
                for target, capacity, _ in self.edges[node]:
                    if capacity > 0 and level[target] < 0:
                        level[target] = level[node] + 1
                        queue.append(target)
            if level[sink] < 0:
                return total
            cursor = [0] * len(self.edges)

            def push(node, amount):
                if node == sink:
                    return amount
                while cursor[node] < len(self.edges[node]):
                    edge = self.edges[node][cursor[node]]
                    target, capacity, reverse = edge
                    if capacity > 0 and level[target] == level[node] + 1:
                        moved = push(target, min(amount, capacity))
                        if moved:
                            edge[1] -= moved
                            self.edges[target][reverse][1] += moved
                            return moved
                    cursor[node] += 1
                return 0

            while True:
                moved = push(source, 10**18)
                if not moved:
                    break
                total += moved


def oracle(text):
    tokens = [int(value) for value in text.split()]
    student_count = tokens[0]
    points = tokens[1:1 + student_count]
    target = points[0] - 1
    losses = [max(0, value - target) for value in points[1:]]
    capacities = [target - value for value in points[1:] if value <= target]
    required = sum(losses)
    if required == 0:
        return "0\n"
    if not capacities:
        return "impossible\n"

    def feasible(limit):
        source = 0
        giver_base = 1
        receiver_base = giver_base + len(losses)
        sink = receiver_base + len(capacities)
        network = Dinic(sink + 1)
        for index, loss in enumerate(losses):
            if loss:
                network.add_edge(source, giver_base + index, loss)
        for index, capacity in enumerate(capacities):
            if capacity:
                network.add_edge(receiver_base + index, sink, capacity)
        for giver in range(len(losses)):
            for receiver in range(len(capacities)):
                if losses[giver] and capacities[receiver]:
                    network.add_edge(giver_base + giver, receiver_base + receiver, limit)
        return network.max_flow(source, sink) == required

    high = max(losses)
    if not feasible(high):
        return "impossible\n"
    low = 0
    while low < high:
        middle = (low + high) // 2
        if feasible(middle):
            high = middle
        else:
            low = middle + 1
    return str(low) + "\n"


def second_oracle(text):
    tokens = [int(value) for value in text.split()]
    student_count = tokens[0]
    points = tokens[1:1 + student_count]
    target = points[0] - 1
    losses = sorted((value - target for value in points[1:] if value > target), reverse=True)
    capacities = sorted(target - value for value in points[1:] if value <= target)
    if not losses:
        return "0\n"
    if not capacities:
        return "impossible\n"
    loss_prefix = [0]
    for loss in losses:
        loss_prefix.append(loss_prefix[-1] + loss)
    capacity_prefix = [0]
    for capacity in capacities:
        capacity_prefix.append(capacity_prefix[-1] + capacity)

    def feasible(limit):
        for size in range(1, len(losses) + 1):
            bound = limit * size
            index = bisect.bisect_right(capacities, bound)
            available = capacity_prefix[index] + bound * (len(capacities) - index)
            if loss_prefix[size] > available:
                return False
        return True

    high = losses[0]
    if not feasible(high):
        return "impossible\n"
    low = 0
    while low < high:
        middle = (low + high) // 2
        if feasible(middle):
            high = middle
        else:
            low = middle + 1
    return str(low) + "\n"


SAMPLE = """4
500
300
900
100
"""
SAMPLE_OUT = """202
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SAMPLE) == second_oracle(SAMPLE)
assert oracle("1\n7\n") == "0\n"
assert oracle("2\n1\n5\n") == "impossible\n"
assert oracle("4\n10\n4\n20\n1\n") == "6\n"


def write(name, points):
    text = str(len(points)) + "\n" + "\n".join(str(value) for value in points) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 5])
    write("3_wide", [10**6] + [1] * 50)
    rng = random.Random(20261130)
    write("4_random", [rng.randint(1, 1000) for _ in range(12)])
    write("5_io", [500000] + [rng.randint(1, 10**6) for _ in range(120)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [500, 300, 900, 100])
build()
