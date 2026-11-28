#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """6 6
0 1
0 2
1 2
3 4
3 5
4 5
"""
SAMPLE_OUTPUT = "1\n"


def oracle(text):
    parts = list(map(int, text.split()))
    city_count, road_count = parts[0], parts[1]
    neighbors = [[] for _ in range(city_count)]
    cursor = 2
    for _ in range(road_count):
        first = parts[cursor]; second = parts[cursor + 1]
        cursor += 2
        neighbors[first].append(second)
        neighbors[second].append(first)
    visited = [False] * city_count
    component_count = 0
    for start in range(city_count):
        if visited[start]:
            continue
        component_count += 1
        visited[start] = True
        stack = [start]
        while stack:
            city = stack.pop()
            for neighbor in neighbors[city]:
                if not visited[neighbor]:
                    visited[neighbor] = True
                    stack.append(neighbor)
    return str(component_count - 1) + "\n"


def write(name, city_count, edges):
    input_text = "%d %d\n" % (city_count, len(edges))
    input_text += "".join("%d %d\n" % (first, second) for first, second in edges)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1 0\n") == "0\n"
assert oracle("2 1\n0 1\n") == "0\n"
assert oracle("4 2\n0 1\n2 3\n") == "1\n"


def trace_example():
    edges = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
    print(6, len(edges), "components 2, roads needed 1")


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", 6, [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)])
    write("2_edges", 4, [(0, 1), (2, 3)])
    write("3_wide", 100000, [(i, i + 1) for i in range(0, 99998, 2)])
    random.seed(31415)
    write("4_random", 2000,
          [(random.randrange(2000), random.randrange(2000)) for _ in range(6000)])
    write("5_io", 200000,
          [(random.randrange(200000), random.randrange(200000)) for _ in range(400000)])
