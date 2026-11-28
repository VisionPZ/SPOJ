#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    scan = 0
    lines = []
    while scan < len(tokens):
        city_count = int(tokens[scan]); scan += 1
        if city_count == 0:
            break
        adjacency = [[] for _ in range(city_count + 1)]
        for _ in range(city_count - 1):
            city_a = int(tokens[scan]); scan += 1
            city_b = int(tokens[scan]); scan += 1
            cost = int(tokens[scan]); scan += 1
            adjacency[city_a].append((city_b, cost))
            adjacency[city_b].append((city_a, cost))
        query_count = int(tokens[scan]); scan += 1
        for _ in range(query_count):
            source = int(tokens[scan]); scan += 1
            target = int(tokens[scan]); scan += 1
            queue = deque([(source, 0)])
            seen = {source}
            answer = 0
            while queue:
                city, largest = queue.popleft()
                if city == target:
                    answer = largest
                    break
                for neighbor, cost in adjacency[city]:
                    if neighbor not in seen:
                        seen.add(neighbor)
                        queue.append((neighbor, max(largest, cost)))
            lines.append(str(answer))
        lines.append("")
    if not lines:
        return ""
    return "\n".join(lines) + "\n"


SAMPLE = """6
1 2 1
1 3 5
3 4 3
3 5 8
1 6 2
3
2 6
5 2
4 6
0
"""
SAMPLE_OUT = "2\n8\n5\n\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n1 2 7\n1\n1 2\n0\n") == "7\n\n"
assert oracle("3\n1 2 4\n2 3 9\n2\n1 3\n3 1\n0\n") == "9\n9\n\n"
assert oracle("0\n") == ""


def make_case(city_count, query_count, rng):
    lines = [str(city_count)]
    for city in range(2, city_count + 1):
        parent = rng.randint(1, city - 1)
        cost = rng.randint(0, 10 ** 9)
        lines.append(f"{parent} {city} {cost}")
    lines.append(str(query_count))
    for _ in range(query_count):
        first = rng.randint(1, city_count)
        second = rng.randint(1, city_count)
        while first == second:
            second = rng.randint(1, city_count)
        lines.append(f"{first} {second}")
    return "\n".join(lines) + "\n0\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("1_sample", SAMPLE)
    write("2_edges", "2\n1 2 1000000000\n1\n2 1\n0\n")
    rng = random.Random(20261126)
    write("3_wide", make_case(200, 100, rng))
    write("4_random", make_case(60, 200, rng))
    write("5_io", make_case(1000, 3000, rng))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
