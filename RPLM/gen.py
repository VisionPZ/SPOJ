#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    case_total = tokens[pos]; pos += 1
    lines = []
    for case_index in range(case_total):
        rooms = tokens[pos]; pos += 1
        tunnels = tokens[pos]; pos += 1
        hammers = tokens[pos]; pos += 1
        adjacency = [[] for _ in range(rooms)]
        for _ in range(tunnels):
            origin, target, opening, collapse, length, travel = tokens[pos:pos + 6]
            pos += 6
            record = (target, opening, collapse, length, travel)
            adjacency[origin].append(record)
            adjacency[target].append((origin, opening, collapse, length, travel))
        best = {}
        for room in range(rooms):
            for used in range(hammers + 1):
                best[(room, used)] = (10 ** 18, 10 ** 18)
        best[(0, 0)] = (0, 0)
        for _ in range(rooms * (hammers + 1) + 5):
            changed = False
            for room in range(rooms):
                for used in range(hammers + 1):
                    current_time, current_distance = best[(room, used)]
                    if current_time >= 10 ** 18:
                        continue
                    for target, opening, collapse, length, travel in adjacency[room]:
                        options = []
                        if current_time < opening:
                            wait_arrival = opening + travel
                            options.append((wait_arrival, 1 if wait_arrival > collapse else 0, current_distance + length))
                            early_arrival = current_time + travel
                            options.append((early_arrival, 1 + (1 if early_arrival > collapse else 0), current_distance + length))
                        elif current_time <= collapse:
                            arrival = current_time + travel
                            options.append((arrival, 1 if arrival > collapse else 0, current_distance + length))
                        else:
                            options.append((current_time + travel, 1, current_distance + length))
                        for arrival, need, distance in options:
                            next_used = used + need
                            if next_used > hammers:
                                continue
                            key = (target, next_used)
                            if (arrival, distance) < best[key]:
                                best[key] = (arrival, distance)
                                changed = True
            if not changed:
                break
        answer = min(best[(rooms - 1, used)] for used in range(hammers + 1))
        if answer[0] >= 10 ** 18:
            lines.append("Scenario #%d: -1" % (case_index + 1))
        else:
            lines.append("Scenario #%d: %d %d" % (case_index + 1, answer[0], answer[1]))
    return "\n".join(lines) + "\n"


SAMPLE = """4
6 6 2
0 1 1 18 3 3
0 2 1 12 4 4
0 4 1 3 5 5
2 3 1 8 2 2
3 4 1 5 3 3
4 5 5 20 1 1
6 6 1
0 1 1 18 3 3
0 2 1 12 4 4
0 4 1 3 5 5
2 3 1 8 2 2
3 4 1 5 3 3
4 5 5 20 1 1
6 6 0
0 1 1 18 3 3
0 2 1 12 4 4
0 4 1 3 5 5
2 3 1 8 2 2
3 4 8 25 3 3
4 5 5 20 1 1
3 3 0
0 1 0 5 4 4
1 2 0 5 2 2
0 2 0 5 6 6
"""
SAMPLE_OUT = """Scenario #1: 6 6
Scenario #2: 7 6
Scenario #3: 12 10
Scenario #4: -1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1 0\n0 1 1 2 1 1\n") == "Scenario #1: 2 1\n"
assert oracle("1\n2 1 1\n0 1 5 10 1 1\n") == "Scenario #1: 1 1\n"
assert oracle("1\n2 1 0\n0 1 5 10 1 1\n") == "Scenario #1: 6 1\n"
assert oracle("1\n3 2 1\n0 1 1 10 1 1\n1 2 5 6 1 1\n0 2 1 10 5 5\n") == "Scenario #1: 3 2\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for rooms, hammer_supply, edges in cases:
        text += "%d %d %d\n" % (rooms, len(edges), hammer_supply)
        for edge in edges:
            text += " ".join(str(value) for value in edge) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def random_case(rng, rooms, tunnel_count, hammer_supply):
    edges = []
    for _ in range(tunnel_count):
        origin = rng.randrange(rooms)
        target = rng.randrange(rooms)
        if target == origin:
            target = (origin + 1) % rooms
        opening = rng.randint(1, 20)
        collapse = opening + rng.randint(1, 60)
        length = rng.randint(1, 10)
        travel = rng.randint(1, 10)
        edges.append((origin, target, opening, collapse, length, travel))
    return rooms, hammer_supply, edges


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        (2, 1, [(0, 1, 1, 10, 1, 1)]),
        (2, 0, [(0, 1, 5, 6, 2, 4)]),
        (3, 2, [(0, 1, 1, 3, 2, 4), (1, 2, 5, 10, 3, 2)]),
    ])
    write("3_wide", [random_case(rng, 20, 60, 3) for _ in range(4)])
    write("4_random", [random_case(rng, rng.randint(3, 10), rng.randint(3, 25), rng.randint(0, 3)) for _ in range(10)])
    write("5_io", [random_case(rng, 12, 30, 2) for _ in range(10)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
