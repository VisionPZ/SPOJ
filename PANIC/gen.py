#!/usr/bin/env python3
"""Test generator and independent oracle for PANIC.

The oracle simulates every crowd as a timed event and follows the crowd chain
that a person can join. The solver uses a distance formula instead, so the two
methods are independent. Small cases also run through an exhaustive checker.
"""
import heapq
import random
import sys
from fractions import Fraction
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.setrecursionlimit(200000)


def parse(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    cases = []
    for _ in range(count):
        node_count = int(tokens[cursor]); cursor += 1
        street_count = int(tokens[cursor]); cursor += 1
        bag_count = int(tokens[cursor]); cursor += 1
        edges = []
        for _ in range(street_count):
            u = int(tokens[cursor]); cursor += 1
            v = int(tokens[cursor]); cursor += 1
            uv = int(tokens[cursor]); cursor += 1
            vu = int(tokens[cursor]); cursor += 1
            edges.append((u, v, uv, vu))
        bags = []
        for _ in range(bag_count):
            bags.append(int(tokens[cursor])); cursor += 1
        cases.append((node_count, edges, bags))
    return cases


def shortest(node_count, edges, bags):
    adj = [[] for _ in range(node_count + 1)]
    weight = {}
    for u, v, uv, vu in edges:
        adj[u].append(v); adj[v].append(u)
        weight[(u, v)] = uv; weight[(v, u)] = vu
    dist = [None] * (node_count + 1)
    queue = []
    for bag in bags:
        dist[bag] = 0
        heapq.heappush(queue, (0, bag))
    while queue:
        current, node = heapq.heappop(queue)
        if current != dist[node]:
            continue
        for neighbour in adj[node]:
            candidate = current + weight[(node, neighbour)]
            if dist[neighbour] is None or candidate < dist[neighbour]:
                dist[neighbour] = candidate
                heapq.heappush(queue, (candidate, neighbour))
    return adj, weight, dist


def parent_sets(node_count, edges, bags, adj, weight, dist):
    bag_set = set(bags)
    parents = [set() for _ in range(node_count + 1)]
    for node in range(1, node_count + 1):
        if node in bag_set or dist[node] is None:
            continue
        for neighbour in adj[node]:
            if dist[neighbour] is not None and dist[neighbour] + weight[(neighbour, node)] == dist[node]:
                parents[node].add(neighbour)
    return parents


def oracle(text):
    cases = parse(text)
    answers = []
    for node_count, edges, bags in cases:
        adj, weight, dist = shortest(node_count, edges, bags)
        hidden = [node for node in range(1, node_count + 1) if dist[node] is None]
        if hidden:
            answers.append(hidden)
            continue
        parents = parent_sets(node_count, edges, bags, adj, weight, dist)
        crowds = {}
        for node in range(1, node_count + 1):
            for neighbour in adj[node]:
                if neighbour in parents[node]:
                    continue
                departure = Fraction(dist[node])
                arrival = departure + weight[(node, neighbour)]
                crowds[(node, neighbour)] = [departure, arrival, False, None]
        departures = sorted((crowd[0], key) for key, crowd in crowds.items())
        active = []
        for _, key in departures:
            crowd = crowds[key]
            if crowd[2]:
                continue
            earliest = None
            for other_key in active:
                other = crowds[other_key]
                if other_key[0] == key[1] and other_key[1] == key[0] \
                        and other[0] < crowd[1] and crowd[0] < other[1]:
                    forward = weight[key]
                    backward = weight[other_key]
                    meet = (crowd[0] * backward + other[0] * forward + forward * backward) / (forward + backward)
                    if earliest is None or meet < earliest[0]:
                        earliest = (meet, other_key)
            if earliest is not None:
                meet, other_key = earliest
                crowd[2] = True; crowd[3] = meet
                crowds[other_key][2] = True; crowds[other_key][3] = meet
            else:
                active.append(key)

        @lru_cache(maxsize=None)
        def survive(key):
            crowd = crowds[key]
            if crowd[2]:
                return crowd[3]
            node, neighbour = key
            if crowd[1] == dist[neighbour]:
                follow = [(neighbour, nxt) for nxt in adj[neighbour] if nxt not in parents[neighbour]]
                if not follow:
                    return crowd[1]
                return max(survive(item) for item in follow)
            return crowd[1]

        values = []
        for node in range(1, node_count + 1):
            keys = [(node, neighbour) for neighbour in adj[node] if neighbour not in parents[node]]
            values.append(max((survive(key) for key in keys), default=Fraction(dist[node])))
        best = max(values)
        answers.append([index + 1 for index, value in enumerate(values) if value == best])
    return "\n".join(" ".join(str(node) for node in answer) for answer in answers) + "\n"


def exhaustive(text):
    """Second checker: direct recursion over crowd chains without a global event pass."""
    cases = parse(text)
    lines = []
    for node_count, edges, bags in cases:
        adj, weight, dist = shortest(node_count, edges, bags)
        hidden = [node for node in range(1, node_count + 1) if dist[node] is None]
        if hidden:
            lines.append(" ".join(str(node) for node in hidden))
            continue
        parents = parent_sets(node_count, edges, bags, adj, weight, dist)
        bag_set = set(bags)

        def outgoing(node):
            return [nxt for nxt in adj[node] if nxt not in parents[node]]

        def opposing_time(node, neighbour):
            if neighbour in bag_set:
                return Fraction(0)
            return Fraction(dist[neighbour])

        @lru_cache(maxsize=None)
        def best_from(node):
            result = Fraction(dist[node])
            for neighbour in outgoing(node):
                forward = weight[(node, neighbour)]
                backward = weight[(neighbour, node)]
                arrive = Fraction(dist[node]) + forward
                opposed = opposing_time(node, neighbour)
                if opposed < arrive and Fraction(dist[node]) < opposed + backward:
                    meet = (Fraction(dist[node]) * backward + opposed * forward + forward * backward) / (forward + backward)
                    value = meet
                elif arrive == dist[neighbour]:
                    value = best_from(neighbour)
                else:
                    value = arrive
                if value > result:
                    result = value
            return result

        values = [best_from(node) for node in range(1, node_count + 1)]
        top = max(values)
        lines.append(" ".join(str(index + 1) for index, value in enumerate(values) if value == top))
    return "\n".join(lines) + "\n"


def render(cases):
    chunks = [str(len(cases))]
    for node_count, edges, bags in cases:
        chunks.append(f"{node_count} {len(edges)} {len(bags)}")
        for u, v, uv, vu in edges:
            chunks.append(f"{u} {v} {uv} {vu}")
        if bags:
            chunks.append(" ".join(str(bag) for bag in bags))
        else:
            chunks.append("")
    return "\n".join(chunks) + "\n"


def write(name, cases):
    text = render(cases)
    expected = oracle(text)
    if exhaustive(text) != expected:
        raise AssertionError(f"oracle mismatch in {name}")
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


SAMPLE = (
    "2\n\n4 5 2\n1 2 10 10\n2 4 30 30\n3 2 10 10\n4 3 50 5\n3 1 5  50\n1 2\n\n2 0 1\n2\n"
)
assert oracle(SAMPLE) == "2 3 4\n1\n"
assert exhaustive(SAMPLE) == "2 3 4\n1\n"

ONE_EDGE = "1\n2 1 1\n1 2 10 10\n1\n"
assert oracle(ONE_EDGE) == "1 2\n"
BOTH_BAGS = "1\n2 1 2\n1 2 10 10\n1 2\n"
assert oracle(BOTH_BAGS) == "1 2\n"
NO_BAGS = "1\n3 0 0\n\n"
assert oracle(NO_BAGS) == "1 2 3\n"
MULTI_PARENT = "1\n3 2 2\n2 3 4 2\n1 2 2 5\n3 1\n"
assert oracle(MULTI_PARENT) == "1 2 3\n"


def edge_cases():
    cases = []
    cases.append((1, [], []))
    cases.append((1, [], [1]))
    cases.append((3, [], []))
    cases.append((2, [], [1]))
    cases.append((2, [], [1, 2]))
    cases.append((2, [(1, 2, 10, 10)], [1]))
    cases.append((2, [(1, 2, 10, 10)], [1, 2]))
    cases.append((3, [(1, 2, 3, 7), (2, 3, 5, 2)], [2]))
    cases.append((3, [(1, 2, 3, 5), (1, 3, 9, 5), (2, 3, 9, 4)], [3, 2]))
    cases.append((3, [(2, 3, 4, 2), (1, 2, 2, 5)], [3, 1]))
    cases.append((4, [(1, 2, 1, 1), (2, 3, 1, 1), (3, 4, 1, 1), (4, 1, 1, 1)], [1]))
    cases.append((4, [(1, 2, 1, 3), (1, 3, 2, 2), (1, 4, 3, 1)], [1]))
    cases.append((5, [(1, 2, 4, 1), (2, 3, 1, 4), (3, 4, 4, 1), (4, 5, 1, 4)], [1, 5]))
    cases.append((4, [(1, 2, 5, 2), (3, 4, 2, 5)], [1]))
    cases.append((4, [(1, 2, 1, 2), (2, 3, 3, 4), (3, 4, 5, 6), (1, 4, 7, 8)], [2, 4]))
    return cases


def wide_cases():
    cases = []
    cases.append((2000, [], []))
    chain = [(i, i + 1, 3, 5) for i in range(1, 2000)]
    cases.append((2000, chain, [1]))
    cases.append((2000, chain, [1000]))
    star = [(1, i, i % 17 + 1, i % 13 + 1) for i in range(2, 2001)]
    cases.append((2000, star, [1]))
    cases.append((1200, [(i, i + 1, 2, 3) for i in range(1, 1200)] + [(1, 1200, 7, 11)], [1, 600]))
    return cases


def random_cases(count, seed, max_nodes, max_edges):
    rng = random.Random(seed)
    cases = []
    for _ in range(count):
        node_count = rng.randint(2, max_nodes)
        pairs = [(u, v) for u in range(1, node_count + 1) for v in range(u + 1, node_count + 1)]
        rng.shuffle(pairs)
        street_count = min(len(pairs), rng.randint(0, max_edges))
        edges = [(u, v, rng.randint(1, 1000), rng.randint(1, 1000)) for u, v in pairs[:street_count]]
        bag_count = rng.randint(0, max(1, node_count // 4))
        bags = rng.sample(range(1, node_count + 1), bag_count)
        cases.append((node_count, edges, bags))
    return cases


def io_cases():
    cases = []
    for _ in range(60):
        cases.append((2500, [], []))
    for index in range(20):
        node_count = 1200
        edges = [(i, i + 1, index % 9 + 1, index % 7 + 1) for i in range(1, node_count)]
        cases.append((node_count, edges, [1]))
    return cases


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

sample_cases = parse(SAMPLE)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE))

write("2_edges", edge_cases())
write("3_wide", wide_cases())
write("4_random", random_cases(40, 20261124, 90, 260))
write("5_io", io_cases())
