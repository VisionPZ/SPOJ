#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    server_count = tokens[0]
    wire_count = tokens[1]
    neighbors = [[] for _ in range(server_count)]
    cursor = 2
    for _ in range(wire_count):
        first_server = tokens[cursor]
        second_server = tokens[cursor + 1]
        cursor += 2
        neighbors[first_server].append(second_server)
        neighbors[second_server].append(first_server)
    visited = [False] * server_count
    components = 0
    for start in range(server_count):
        if visited[start]:
            continue
        components += 1
        visited[start] = True
        stack = [start]
        while stack:
            node = stack.pop()
            for neighbor in neighbors[node]:
                if not visited[neighbor]:
                    visited[neighbor] = True
                    stack.append(neighbor)
    return str(components) + "\n"


SAMPLE = """6 3
1 2
3 4
5 0
"""
SAMPLE_OUT = """3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("11 9\n0 10\n1 6\n1 8\n2 7\n2 8\n3 4\n3 6\n4 7\n4 10\n") == "3\n"
assert oracle("5 2\n0 4\n1 4\n") == "3\n"
assert oracle("5 1\n1 2\n") == "4\n"
assert oracle("4 2\n1 3\n0 2\n") == "2\n"
assert oracle("1 0\n") == "1\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1 0\n")
    write("3_wide", "600 0\n")
    rng = random.Random(20261126)
    pairs = [(rng.randrange(600), rng.randrange(600)) for _ in range(451)]
    write("4_random", "600 " + str(len(pairs)) + "\n" +
          "".join(f"{first} {second}\n" for first, second in pairs))
    pairs = [(rng.randrange(600), rng.randrange(600)) for _ in range(600)]
    write("5_io", "600 " + str(len(pairs)) + "\n" +
          "".join(f"{first} {second}\n" for first, second in pairs))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
