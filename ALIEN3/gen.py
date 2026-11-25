#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    pos = 0
    case_total = int(tokens[pos]); pos += 1
    lines = []
    for case_index in range(case_total):
        count = int(tokens[pos]); pos += 1
        teleporters = int(tokens[pos]); pos += 1
        values = [int(tokens[pos + index]) for index in range(teleporters)]
        pos += teleporters
        destination = int(tokens[pos]); pos += 1
        limit = int(tokens[pos]); pos += 1
        start = (0, 0)
        queue = deque([start])
        distance = {start: 0}
        best = -1
        while queue:
            station, mask = queue.popleft()
            moves = distance[(station, mask)]
            if station == destination and moves <= limit:
                best = moves
                break
            if moves >= limit:
                continue
            neighbours = []
            if station < count:
                neighbours.append((station + 1, mask))
            for index, value in enumerate(values):
                if not (mask >> index) & 1:
                    landing = station + value
                    if 0 <= landing <= count:
                        neighbours.append((landing, mask | (1 << index)))
            for neighbour in neighbours:
                if neighbour not in distance:
                    distance[neighbour] = moves + 1
                    queue.append(neighbour)
        lines.append("Scenario #%d: %d" % (case_index + 1, best))
    return "\n".join(lines) + "\n"


SAMPLE = """4
12 6
1 3 4 1 2 -2
10 10
12 6
1 3 2 1 2 -2
10 10
10 2
6 -2
5 10
10 2
1 1
10 5
"""
SAMPLE_OUT = """Scenario #1: 4
Scenario #2: 6
Scenario #3: 3
Scenario #4: -1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n10 1\n3\n10 10\n") == "Scenario #1: 8\n"
assert oracle("1\n10 1\n-3\n0 10\n") == "Scenario #1: 0\n"
assert oracle("1\n10 2\n1 1\n10 3\n") == "Scenario #1: -1\n"
assert oracle("1\n5 1\n5\n5 1\n") == "Scenario #1: 1\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    for count, values, destination, limit in cases:
        text += "%d %d\n" % (count, len(values))
        text += " ".join(str(value) for value in values) + "\n"
        text += "%d %d\n" % (destination, limit)
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        (10, [100], 10, 5),
        (10, [-100], 0, 1),
        (10, [5, -2], 5, 2),
    ])
    write("3_wide", [
        (100, [rng.randint(-100, 100) for _ in range(10)], rng.randint(0, 100), 50)
        for _ in range(10)
    ])
    random_cases = []
    for _ in range(20):
        board_size = rng.randint(10, 100)
        random_cases.append((board_size,
                             [rng.randint(-100, 100) for _ in range(rng.randint(1, 9))],
                             rng.randint(0, board_size), rng.randint(1, 50)))
    write("4_random", random_cases)
    write("5_io", [
        (20, [rng.randint(-20, 20) for _ in range(4)], rng.randint(0, 20), 50)
        for _ in range(50)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
