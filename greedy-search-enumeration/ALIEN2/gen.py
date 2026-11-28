#!/usr/bin/env python3
import heapq
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def dijkstra_costs(train_a, train_b):
    stations = len(train_a)
    infinity = 10 ** 18
    distance = [[infinity, infinity] for _ in range(stations)]
    distance[0][0] = train_a[0]
    distance[0][1] = train_b[0]
    queue = [(train_a[0], 0, 0), (train_b[0], 0, 1)]
    heapq.heapify(queue)
    while queue:
        cost, station, train = heapq.heappop(queue)
        if cost != distance[station][train]:
            continue
        destination = station + 1
        if destination == stations:
            continue
        switch_cost = train_a[destination] + train_b[destination]
        if train == 0:
            stay_cost = train_a[destination]
        else:
            stay_cost = train_b[destination]
        stay = (cost + stay_cost, destination, train)
        switch = (cost + switch_cost, destination, 1 - train)
        for candidate in (stay, switch):
            if candidate[0] < distance[destination][candidate[2]]:
                distance[destination][candidate[2]] = candidate[0]
                heapq.heappush(queue, candidate)
    return [min(pair) for pair in distance]


def brute_costs(train_a, train_b):
    stations = len(train_a)
    best = [10 ** 18] * stations
    for route in itertools.product((0, 1), repeat=stations):
        cost = train_a[0] if route[0] == 0 else train_b[0]
        best[0] = min(best[0], cost)
        for station in range(1, stations):
            if route[station] == route[station - 1]:
                cost += train_a[station] if route[station] == 0 else train_b[station]
            else:
                cost += train_a[station] + train_b[station]
            best[station] = min(best[station], cost)
    return best


def answer(train_a, train_b, limit):
    costs = dijkstra_costs(train_a, train_b)
    passed = 0
    people = 0
    for station, cost in enumerate(costs):
        if cost <= limit:
            passed = station + 1
            people = cost
    return f"{passed} {people}\n"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    stations = tokens[0]
    limit = tokens[1]
    train_a = tokens[2:2 + stations]
    train_b = tokens[2 + stations:2 + 2 * stations]
    return answer(train_a, train_b, limit)


SAMPLE = """3 10
9 2 4
1 2 9
"""
SAMPLE_OUT = """3 9
"""
SECOND = """5 10
1 7 1 1 1
2 2 2 2 2
"""
SECOND_OUT = """5 9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == SECOND_OUT
assert oracle("5 13\n15 5 10 5 5\n11 1 4 5 5\n") == "2 12\n"
assert oracle("1 10\n11 12\n") == "0 0\n"
assert dijkstra_costs([9, 2, 4], [1, 2, 9]) == brute_costs([9, 2, 4], [1, 2, 9])
assert dijkstra_costs([1, 7, 1], [2, 2, 2]) == brute_costs([1, 7, 1], [2, 2, 2])
assert dijkstra_costs([5, 4, 3, 2], [1, 6, 2, 9]) == brute_costs([5, 4, 3, 2], [1, 6, 2, 9])


def write(name, train_a, train_b, limit):
    text = f"{len(train_a)} {limit}\n" + " ".join(str(v) for v in train_a) + "\n" + \
        " ".join(str(v) for v in train_b) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [100], [100], 50)
    rng = random.Random(20261126)
    wide = [rng.randint(1, 100) for _ in range(10000)]
    write("3_wide", wide, [100] * 10000, 65000)
    write("4_random", [rng.randint(1, 100) for _ in range(500)],
          [rng.randint(1, 100) for _ in range(500)], 3000)
    write("5_io", [rng.randint(1, 100) for _ in range(10000)],
          [rng.randint(1, 100) for _ in range(10000)], 40000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
