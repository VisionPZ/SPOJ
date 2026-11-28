#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(token) for token in text.split()]
    position = 0
    test_count = tokens[position]
    position += 1
    answers = []
    for _ in range(test_count):
        citizen_count = tokens[position]
        road_count = tokens[position + 1]
        position += 2
        flags = tokens[position:position + citizen_count]
        position += citizen_count
        roads = []
        for _ in range(road_count):
            first = tokens[position]
            second = tokens[position + 1]
            cost = tokens[position + 2]
            position += 3
            roads.append((first, second, cost))
        adjacency = [[] for _ in range(citizen_count + 1)]
        for first, second, cost in roads:
            adjacency[first].append((second, cost))
            adjacency[second].append((first, cost))
        reached = [False] * (citizen_count + 1)
        heap = []
        for citizen in range(1, citizen_count + 1):
            if flags[citizen - 1] == 1:
                reached[citizen] = True
                for neighbour, cost in adjacency[citizen]:
                    heapq.heappush(heap, (cost, neighbour))
        total = 0
        connected = sum(reached)
        while heap:
            cost, destination = heapq.heappop(heap)
            if reached[destination]:
                continue
            reached[destination] = True
            total += cost
            connected += 1
            for neighbour, edge_cost in adjacency[destination]:
                if not reached[neighbour]:
                    heapq.heappush(heap, (edge_cost, neighbour))
        answers.append("impossible" if connected < citizen_count else str(total))
    return "\n".join(answers) + "\n"


def brute(test_case):
    citizen_count, flags, roads = test_case
    best = None
    for mask in range(1 << len(roads)):
        parent = list(range(citizen_count + 1))

        def find(node):
            while parent[node] != node:
                node = parent[node]
            return node

        cost = 0
        for index, (first, second, road_cost) in enumerate(roads):
            if mask >> index & 1:
                left = find(first)
                right = find(second)
                if left != right:
                    parent[right] = left
                    cost += road_cost
        component_has_milkman = {}
        ok = True
        for citizen in range(1, citizen_count + 1):
            root = find(citizen)
            component_has_milkman[root] = component_has_milkman.get(root, False) or flags[citizen - 1] == 1
        for citizen in range(1, citizen_count + 1):
            if not component_has_milkman[find(citizen)]:
                ok = False
        if ok and (best is None or cost < best):
            best = cost
    return "impossible" if best is None else str(best)


def case_text(cases):
    text = str(len(cases)) + "\n"
    for citizen_count, flags, roads in cases:
        text += f"{citizen_count} {len(roads)}\n"
        text += " ".join(str(flag) for flag in flags) + "\n"
        for first, second, cost in roads:
            text += f"{first} {second} {cost}\n"
    return text


def oracle_cases(cases):
    return oracle(case_text(cases))


SAMPLE = """1
5 7
0 1 0 1 0
1 2 11
1 3 1
1 5 17
2 3 1
3 5 18
4 5 3
2 4 5
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
TINY = [
    (2, [0, 0], [(1, 2, 5)]),
    (2, [0, 1], [(1, 2, 7)]),
    (3, [1, 0, 0], [(1, 2, 3), (2, 3, 4)]),
    (3, [1, 0, 0], []),
    (4, [0, 1, 0, 0], [(1, 2, 5), (2, 3, 2), (3, 4, 9)]),
]
assert oracle_cases(TINY) == "\n".join(brute(case) for case in TINY) + "\n"
assert oracle_cases([(2, [0, 0], [(1, 2, 5)])]) == "impossible\n"


def write(name, cases):
    (ROOT / "in" / f"{name}.txt").write_text(case_text(cases))
    (ROOT / "out" / f"{name}.out").write_text(oracle_cases(cases))


def build():
    write("2_edges", TINY)
    rng = random.Random(20261126)
    wide_roads = [(rng.randint(1, 100), rng.randint(1, 100), rng.randint(1, 10 ** 9))
                  for _ in range(300)]
    wide_roads = [(first, second, cost) for first, second, cost in wide_roads if first != second]
    write("3_wide", [(100, [rng.randint(0, 1) for _ in range(100)], wide_roads)])
    random_cases = []
    for _ in range(5):
        size = 30
        flags = [rng.randint(0, 1) for _ in range(size)]
        roads = [(rng.randint(1, size), rng.randint(1, size), rng.randint(1, 100000))
                 for _ in range(60)]
        roads = [(first, second, cost) for first, second, cost in roads if first != second]
        random_cases.append((size, flags, roads))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        size = 5
        flags = [rng.randint(0, 1) for _ in range(size)]
        roads = [(rng.randint(1, size), rng.randint(1, size), rng.randint(1, 1000))
                 for _ in range(6)]
        roads = [(first, second, cost) for first, second, cost in roads if first != second]
        io_cases.append((size, flags, roads))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
SAMPLE_CASES = [(5, [0, 1, 0, 1, 0],
                [(1, 2, 11), (1, 3, 1), (1, 5, 17), (2, 3, 1),
                 (3, 5, 18), (4, 5, 3), (2, 4, 5)])]
write("1_sample", SAMPLE_CASES)
build()
