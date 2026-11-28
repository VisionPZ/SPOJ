#!/usr/bin/env python3
from collections import deque
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle(text):
    tokens = text.split()
    street_count = int(tokens[0])
    intersection_count = int(tokens[1])
    cursor = 2
    streets = [[] for _ in range(intersection_count + 1)]
    for _ in range(street_count):
        start = int(tokens[cursor]); cursor += 1
        end = int(tokens[cursor]); cursor += 1
        travel = int(tokens[cursor]); cursor += 1
        streets[start].append((end, travel))
        streets[end].append((start, travel))
    green = [0] * (intersection_count + 1)
    red = [0] * (intersection_count + 1)
    for intersection in range(1, intersection_count + 1):
        green[intersection] = int(tokens[cursor]); cursor += 1
        red[intersection] = int(tokens[cursor]); cursor += 1
    distances = [INF] * (intersection_count + 1)
    distances[1] = 0
    queued = [False] * (intersection_count + 1)
    queue = deque([1])
    queued[1] = True
    while queue:
        current = queue.popleft()
        queued[current] = False
        cycle = green[current] + red[current]
        if cycle == 0:
            leave = distances[current]
        else:
            phase = distances[current] % cycle
            leave = distances[current] if phase < green[current] else distances[current] + cycle - phase
        for target, travel in streets[current]:
            arrival = leave + travel
            if arrival < distances[target]:
                distances[target] = arrival
                if not queued[target]:
                    queue.append(target)
                    queued[target] = True
    return str(distances[intersection_count]) + "\n"


SAMPLE = """7 6
1 2 4
1 3 1
3 5 2
2 4 2
2 5 6
5 4 2
5 6 10
0 0
5 5
1 20
2 5
10 2
0 0
"""
SAMPLE_OUT = """19
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 2\n1 2 7\n0 0\n0 0\n") == "7\n"
assert oracle("2 3\n1 2 5\n2 3 5\n0 0\n5 5\n0 0\n") == "15\n"


def write(name, street_count_extra, intersections, rng):
    edges = [(index, index + 1, rng.randint(1, 1000)) for index in range(1, intersections)]
    for _ in range(street_count_extra):
        start = rng.randint(1, intersections)
        end = rng.randint(1, intersections)
        if start != end:
            edges.append((start, end, rng.randint(1, 1000)))
    if intersections == 2:
        edges = [(1, 2, rng.randint(1, 1000))]
    lines = [f"{len(edges)} {intersections}"]
    lines.extend(f"{start} {end} {travel}" for start, end, travel in edges)
    for intersection in range(1, intersections + 1):
        if intersection in (1, intersections):
            lines.append("0 0")
        else:
            lines.append(f"{rng.randint(1, 1000)} {rng.randint(1, 1000)}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", 0, 2, rng)
    write("3_wide", 2000, 1000, rng)
    write("4_random", 40, 20, rng)
    write("5_io", 20000, 1000, rng)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
def trace_example():
    print("1 -> 2: arrive 4, green, leave 4")
    print("2 -> 4: arrive 6, red, leave 7")
    print("4 -> 5: arrive 9, green, leave 9")
    print("5 -> 6: arrive 19")


build()
trace_example()
