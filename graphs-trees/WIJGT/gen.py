#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def box(x, y, length):
    if length > 0:
        return (x, x + length, y, y)
    if length < 0:
        return (x, x, y, y - length)
    return (x, x, y, y)


def distance(first, second):
    ax0, ax1, ay0, ay1 = first
    bx0, bx1, by0, by1 = second
    gap_x = max(0, ax0 - bx1, bx0 - ax1)
    gap_y = max(0, ay0 - by1, by0 - ay1)
    return math.hypot(gap_x, gap_y)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    lines = []
    while position < len(tokens):
        wall_count = tokens[position]
        position += 1
        if wall_count == 0:
            break
        boxes = []
        for _ in range(wall_count):
            boxes.append(box(tokens[position], tokens[position + 1], tokens[position + 2]))
            position += 3
        best = [[0.0] * wall_count for _ in range(wall_count)]
        for first in range(wall_count):
            for second in range(wall_count):
                if first != second:
                    best[first][second] = distance(boxes[first], boxes[second])
        for middle in range(wall_count):
            for first in range(wall_count):
                for second in range(wall_count):
                    candidate = max(best[first][middle], best[middle][second])
                    if candidate < best[first][second]:
                        best[first][second] = candidate
        lines.append(f"{best[0][1]:.2f}")
    return "\n".join(lines) + "\n"


def threshold_answer(boxes):
    count = len(boxes)
    ordered = []
    for first in range(count):
        for second in range(first + 1, count):
            ordered.append((distance(boxes[first], boxes[second]), first, second))
    ordered.sort()
    parent = list(range(count))

    def find(node):
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    for length, first, second in ordered:
        first_root = find(first)
        second_root = find(second)
        if first_root != second_root:
            parent[second_root] = first_root
        if find(0) == find(1):
            return length
    return 0.0


def case_text(walls):
    lines = [str(len(walls))]
    lines += [f"{x} {y} {length}" for x, y, length in walls]
    return "\n".join(lines) + "\n"


SAMPLE = """14
1 1 5
6 8 2
7 2 -2
5 3 3
2 5 2
2 3 2
2 3 -2
4 3 -2
0 7 1
1 8 2
3 6 -2
4 7 2
6 6 1
6 6 -2
3
-10 0 20
-5 1 10
50 50 100
0
"""
SAMPLE_OUT = """1.41
1.00
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n0 0 5\n0 0 5\n0\n") == "0.00\n"
assert oracle("2\n0 0 3\n2 0 0\n0\n") == "0.00\n"
assert oracle("2\n0 0 3\n5 0 -4\n0\n") == "2.00\n"
assert oracle("2\n0 0 0\n3 4 0\n0\n") == "5.00\n"
assert threshold_answer([box(0, 0, 3), box(3, 0, 4), box(20, 20, 0)]) == 0.0

rng = random.Random(20261126)
for _ in range(30):
    walls = [(rng.randint(-10, 10), rng.randint(-10, 10), rng.choice((-6, -3, -1, 0, 1, 3, 6)))
             for _ in range(rng.randint(2, 7))]
    text = case_text(walls) + "0\n"
    assert oracle(text) == f"{threshold_answer([box(*wall) for wall in walls]):.2f}\n"


def write(name, cases):
    text = "".join(cases) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        case_text([(0, 0, 4), (4, 0, 3)]),
        case_text([(0, 0, 0), (3, 4, 0)]),
        case_text([(0, 0, 2), (5, 0, -3)]),
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(50):
        walls = [(rng.randint(-10000, 10000), rng.randint(-10000, 10000),
                  rng.choice((-10000, -17, -1, 0, 1, 17, 10000))) for _ in range(60)]
        wide.append(case_text(walls))
    write("3_wide", wide)
    mixed = []
    for _ in range(50):
        size = rng.randint(2, 40)
        walls = [(rng.randint(-500, 500), rng.randint(-500, 500),
                  rng.randint(-100, 100)) for _ in range(size)]
        mixed.append(case_text(walls))
    write("4_random", mixed)
    io = []
    for _ in range(150):
        walls = [(index * 3, 0, 2) for index in range(30)]
        walls.append((0, 1000, 20))
        io.append(case_text(walls))
    write("5_io", io)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
