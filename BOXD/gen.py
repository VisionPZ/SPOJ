#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def rectangle_distance(first, second):
    x_low_first, x_high_first, y_low_first, y_high_first = first
    x_low_second, x_high_second, y_low_second, y_high_second = second
    gap_x = max(x_low_first - x_high_second, x_low_second - x_high_first, 0)
    gap_y = max(y_low_first - y_high_second, y_low_second - y_high_first, 0)
    return math.hypot(gap_x, gap_y)


def dijkstra(boxes, source, target):
    count = len(boxes)
    best = [float("inf")] * count
    best[source] = 0.0
    settled = [False] * count
    for _ in range(count):
        current = -1
        for candidate in range(count):
            if not settled[candidate] and (current < 0 or
                                           best[candidate] < best[current]):
                current = candidate
        settled[current] = True
        for neighbor in range(count):
            if not settled[neighbor]:
                candidate_distance = best[current] + rectangle_distance(
                    boxes[current], boxes[neighbor])
                if candidate_distance < best[neighbor]:
                    best[neighbor] = candidate_distance
    return best[target]


def oracle(text):
    boxes = []
    answers = []
    for line in text.splitlines():
        parts = line.split()
        if not parts:
            continue
        if parts[0] == "B":
            first_x, first_y, second_x, second_y = map(int, parts[1:5])
            boxes.append((min(first_x, second_x), max(first_x, second_x),
                          min(first_y, second_y), max(first_y, second_y)))
        else:
            first_box = int(parts[1]) - 1
            second_box = int(parts[2]) - 1
            answers.append(f"{dijkstra(boxes, first_box, second_box):.2f}")
    return "\n".join(answers) + "\n"


SAMPLE = """B -1 2 1 5
B 3 -4 4 1
G 2 1
B 4 -3 6 -2
B 6 -6 8 -4
G 2 3
G 1 4
"""
SAMPLE_OUT = """2.24
0.00
3.24
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("B 0 0 1 1\nB 1 1 2 2\nG 1 2\n") == "0.00\n"
assert oracle("B 0 0 1 1\nB 4 0 5 1\nG 1 2\n") == "3.00\n"
assert oracle("B 0 0 0 0\nB 3 4 3 4\nG 1 2\n") == "5.00\n"
assert oracle("B 0 0 1 1\nB 0 3 1 4\nB 0 6 1 7\nG 1 3\n") == "4.00\n"


def write(name, commands):
    text = "\n".join(commands) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["B 0 0 2 2", "B 1 1 3 3", "G 1 2", "B 5 5 5 5",
                      "G 3 1", "B 5 6 6 7", "G 3 4", "G 4 1"])
    rng = random.Random(20261126)
    commands = []
    for _ in range(20):
        first_x = rng.randint(-1000000, 1000000)
        first_y = rng.randint(-1000000, 1000000)
        commands.append(f"B {first_x} {first_y} "
                        f"{first_x + rng.randint(0, 100000)} "
                        f"{first_y + rng.randint(0, 100000)}")
    for _ in range(30):
        first_box = rng.randint(1, 20)
        second_box = rng.randint(1, 20)
        commands.append(f"G {first_box} {second_box}")
    write("3_wide", commands)
    commands = []
    for _ in range(25):
        first_x = rng.randint(-1000, 1000)
        first_y = rng.randint(-1000, 1000)
        commands.append(f"B {first_x} {first_y} "
                        f"{first_x + rng.randint(0, 300)} "
                        f"{first_y + rng.randint(0, 300)}")
        if rng.random() < 0.6:
            first_box = rng.randint(1, len([line for line in commands
                                            if line.startswith("B")]))
            second_box = rng.randint(1, len([line for line in commands
                                             if line.startswith("B")]))
            commands.append(f"G {first_box} {second_box}")
    write("4_random", commands)
    commands = []
    for box_index in range(20):
        first_x = box_index * 17 - 200
        first_y = box_index * 11 - 150
        commands.append(f"B {first_x} {first_y} {first_x + 9} {first_y + 9}")
    for _ in range(4000):
        first_box = rng.randint(1, 20)
        second_box = rng.randint(1, 20)
        commands.append(f"G {first_box} {second_box}")
    write("5_io", commands)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE.splitlines())
build()
