#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    islands = tokens[0]
    pairs = tokens[2:]
    neighbours = [[] for _ in range(islands)]
    for cursor in range(0, len(pairs), 2):
        first = pairs[cursor] - 1
        second = pairs[cursor + 1] - 1
        neighbours[first].append(second)
        neighbours[second].append(first)
    seen = [False] * islands
    components = 0
    for start in range(islands):
        if seen[start]:
            continue
        components += 1
        seen[start] = True
        queue = deque([start])
        while queue:
            current = queue.popleft()
            for neighbour in neighbours[current]:
                if not seen[neighbour]:
                    seen[neighbour] = True
                    queue.append(neighbour)
    return str(components - 1) + "\n" if islands else "0\n"


SAMPLE = """5 2
1 3
2 4
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 0\n") == "0\n"
assert oracle("2 1\n1 2\n") == "0\n"
assert oracle("3 0\n") == "2\n"
assert oracle("4 2\n1 2\n3 4\n") == "1\n"


def write(name, islands, pairs):
    text = f"{islands} {len(pairs)}\n" + "".join(
        f"{first} {second}\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [])
    write("3_wide", 200, [(index, index + 1) for index in range(1, 200)])
    rng = random.Random(20261126)
    pairs = [(rng.randint(1, 100), rng.randint(1, 100)) for _ in range(80)]
    write("4_random", 100, pairs)
    pairs = [(index * 2 - 1, index * 2) for index in range(1, 1001)]
    write("5_io", 2000, pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, [(1, 3), (2, 4)])
build()
