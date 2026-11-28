#!/usr/bin/env python3
from collections import deque
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def leg_distance(farms, start, end):
    blocked = {farms[index] for index in range(len(farms)) if index not in (start, end)}
    min_x = min(point[0] for point in farms) - 8
    max_x = max(point[0] for point in farms) + 8
    min_y = min(point[1] for point in farms) - 8
    max_y = max(point[1] for point in farms) + 8
    queue = deque()
    start_point = farms[start]
    end_point = farms[end]
    queue.append((start_point[0], start_point[1], 0))
    seen = {(start_point[0], start_point[1])}
    while queue:
        current_x, current_y, steps = queue.popleft()
        if (current_x, current_y) == end_point:
            return steps
        for delta_x, delta_y in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            next_x = current_x + delta_x
            next_y = current_y + delta_y
            if next_x < min_x or next_x > max_x or next_y < min_y or next_y > max_y:
                continue
            if (next_x, next_y) in blocked or (next_x, next_y) in seen:
                continue
            seen.add((next_x, next_y))
            queue.append((next_x, next_y, steps + 1))
    return -1


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    farms = [(tokens[1 + 2 * index], tokens[2 + 2 * index]) for index in range(count)]
    total = 0
    for index in range(count):
        leg = leg_distance(farms, index, (index + 1) % count)
        if leg < 0:
            return "-1\n"
        total += leg
    return str(total) + "\n"


SAMPLE = """4
2 2
2 4
2 1
1 3
"""
SAMPLE_OUT = """12
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n7 9\n") == "0\n"
assert oracle("2\n1 1\n1 3\n") == "4\n"
assert oracle("6\n1 1\n2 2\n1 2\n3 2\n2 1\n2 3\n") == "-1\n"
assert oracle("3\n5 5\n5 8\n9 5\n") == "14\n"


def write(name, farms):
    lines = [str(len(farms))]
    lines.extend(f"{point[0]} {point[1]}" for point in farms)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (2, 2), (1, 2), (3, 2), (2, 1), (2, 3)])
    wide = []
    for row in range(10):
        for column in range(10):
            if (row + column) % 2 == 0:
                wide.append((row * 2 + 1, column * 2 + 1))
    write("3_wide", wide[:100])
    rng = random.Random(20261126)
    for attempt in range(20):
        count = rng.randint(2, 24)
        farms = []
        used = set()
        while len(farms) < count:
            point = (rng.randint(1, 15), rng.randint(1, 15))
            if point not in used:
                used.add(point)
                farms.append(point)
        if oracle("\n".join([str(count)] + [f"{x} {y}" for x, y in farms]) + "\n") != "-1\n":
            write("4_random", farms)
            break
    io_farms = []
    used = set()
    while len(io_farms) < 100:
        point = (rng.randint(1, 20), rng.randint(1, 20))
        if point not in used:
            used.add(point)
            io_farms.append(point)
    write("5_io", io_farms)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 2), (2, 4), (2, 1), (1, 3)])
build()
