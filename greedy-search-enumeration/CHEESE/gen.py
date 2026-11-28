#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def pronunciation_power(name):
    text = name.lower()
    length = len(text)
    total = 0
    for span in range(2, length + 1, 2):
        for start in range(0, length - span + 1):
            piece = text[start:start + span]
            if piece == piece[::-1]:
                total += span
    return total


def max_flow(city_count, roads, sink):
    capacity = [[0] * city_count for _ in range(city_count)]
    for source, target, limit in roads:
        capacity[source][target] += limit
    total = 0
    while True:
        parent = [-1] * city_count
        parent[0] = -2
        queue = deque([0])
        while queue and parent[sink] == -1:
            current = queue.popleft()
            for target in range(city_count):
                if parent[target] == -1 and capacity[current][target] > 0:
                    parent[target] = current
                    queue.append(target)
                    if target == sink:
                        break
        if parent[sink] == -1:
            return total
        bottleneck = 10 ** 30
        cursor = sink
        while cursor != 0:
            bottleneck = min(bottleneck, capacity[parent[cursor]][cursor])
            cursor = parent[cursor]
        cursor = sink
        while cursor != 0:
            previous = parent[cursor]
            capacity[previous][cursor] -= bottleneck
            capacity[cursor][previous] += bottleneck
            cursor = previous
        total += bottleneck


def oracle(text):
    lines = text.strip().split("\n")
    cursor = 0
    answers = []
    while True:
        header = lines[cursor].split()
        cursor += 1
        city_count, road_count, threshold = (int(value) for value in header)
        if city_count == 0 and road_count == 0 and threshold == 0:
            break
        names = lines[cursor:cursor + city_count]
        cursor += city_count
        powers = [pronunciation_power(name) for name in names]
        roads = []
        for _ in range(road_count):
            source, target, limit = (int(value) for value in lines[cursor].split())
            cursor += 1
            roads.append((source, target, limit))
        unique_powers = sorted(set(powers), reverse=True)
        cutoff = unique_powers[min(threshold - 1, len(unique_powers) - 1)]
        chosen = [index for index, power in enumerate(powers) if power >= cutoff]
        answers.append(str(len(chosen)))
        for index in chosen:
            flow = 0 if index == 0 else max_flow(city_count, roads, index)
            answers.append(f"{names[index]} ({powers[index]}) {flow}")
    return "\n".join(answers) + "\n"


SAMPLE = """3 4 2
Curitiba
LalLal
Idappadi
0 1 2
2 1 1
0 2 3
1 2 6
4 5 3
heeymacarena
haay
abbaxx
ddxdd
0 3 20
0 2 10
2 3 5
3 1 10
2 1 20
0 0 0
"""
SAMPLE_OUT = """2
LalLal (12) 3
Idappadi (20) 5
4
heeymacarena (2) 0
haay (2) 20
abbaxx (8) 10
ddxdd (4) 25
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert pronunciation_power("abbaxx") == 8
assert pronunciation_power("aaa") == 4
assert pronunciation_power("aBbAxX") == 8
assert max_flow(3, [(0, 1, 2), (2, 1, 1), (0, 2, 3), (1, 2, 6)], 2) == 5


def write(name, cases):
    blocks = []
    for city_count, names, roads, threshold in cases:
        lines = [f"{city_count} {len(roads)} {threshold}"]
        lines.extend(names)
        lines.extend(f"{source} {target} {limit}" for source, target, limit in roads)
        blocks.append("\n".join(lines))
    text = "\n".join(blocks + ["0 0 0"]) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(rng, city_count, threshold, name_length):
    names = ["".join(rng.choice("aAbBxXyY") for _ in range(rng.randint(1, name_length)))
             for _ in range(city_count)]
    roads = [(0, index, rng.randint(1, 40)) for index in range(1, city_count)]
    for _ in range(city_count):
        source = rng.randrange(city_count)
        target = rng.randrange(city_count)
        if source != target:
            roads.append((source, target, rng.randint(1, 40)))
    return city_count, names, roads, threshold


def build():
    write("2_edges", [(2, ["aa", "bb"], [(0, 1, 5)], 1)])
    rng = random.Random(20261126)
    write("3_wide", [make_case(rng, 10, 3, 14)])
    write("4_random", [make_case(rng, rng.randint(3, 8), rng.randint(1, 3), 12) for _ in range(3)])
    write("5_io", [make_case(rng, rng.randint(4, 6), rng.randint(1, 4), 10) for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
