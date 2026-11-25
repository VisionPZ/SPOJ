#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def format_rupiah(value):
    digits = str(value)
    groups = []
    while len(digits) > 3:
        groups.append(digits[-3:])
        digits = digits[:-3]
    groups.append(digits)
    return ".".join(reversed(groups))


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    result = []
    for _ in range(case_count):
        plant_count = tokens[position]
        price_per_meter = tokens[position + 1]
        position += 2
        plants = []
        for _ in range(plant_count):
            plants.append((tokens[position], tokens[position + 1]))
            position += 2
        edges = []
        for first_index in range(plant_count):
            for second_index in range(first_index + 1, plant_count):
                horizontal = plants[first_index][0] - plants[second_index][0]
                vertical = plants[first_index][1] - plants[second_index][1]
                edges.append((math.hypot(horizontal, vertical), first_index, second_index))
        edges.sort()
        parent = list(range(plant_count))

        def find(vertex):
            while parent[vertex] != vertex:
                parent[vertex] = parent[parent[vertex]]
                vertex = parent[vertex]
            return vertex

        total_length = 0.0
        for length, first_index, second_index in edges:
            first_root = find(first_index)
            second_root = find(second_index)
            if first_root != second_root:
                parent[first_root] = second_root
                total_length += length
        rounded_cost = math.ceil(total_length * price_per_meter - 1e-9)
        result.append("Rp " + format_rupiah(rounded_cost))
    return "\n".join(result) + "\n"


SAMPLE = """2
2 1250
5 3
8 7
3 1375
5 3
8 3
6 7
"""
SAMPLE_OUT = """Rp 6.250
Rp 9.795
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1000\n1 1\n") == "Rp 0\n"
assert oracle("1\n2 1000\n0 0\n3 4\n") == "Rp 5.000\n"
assert oracle("1\n3 1000\n0 0\n3 4\n6 8\n") == "Rp 10.000\n"
assert format_rupiah(1234567) == "1.234.567"


def write_cases(name, cases):
    text = str(len(cases)) + "\n"
    for plant_count, price_per_meter, plants in cases:
        text += f"{plant_count} {price_per_meter}\n"
        for horizontal, vertical in plants:
            text += f"{horizontal} {vertical}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_cases("2_edges", [
        (1, 5000, [(1, 1)]),
        (2, 1000, [(0, 0), (3, 4)]),
        (3, 1000, [(0, 0), (3, 4), (6, 8)]),
    ])
    rng = random.Random(20261126)
    wide = [(1000, 5000, [(rng.randint(1, 1000), rng.randint(1, 200)) for _ in range(1000)])]
    write_cases("3_wide", wide)
    write_cases("4_random", [
        (30, rng.randint(1000, 5000),
         [(rng.randint(1, 1000), rng.randint(1, 200)) for _ in range(30)])
        for _ in range(5)
    ])
    write_cases("5_io", [
        (10, rng.randint(1000, 5000),
         [(rng.randint(1, 1000), rng.randint(1, 200)) for _ in range(10)])
        for _ in range(100)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
