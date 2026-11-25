#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FULL_CIRCLE = 2 * math.pi


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    obstacles = []
    for index in range(count):
        obstacles.append((int(tokens[1 + 3 * index]),
                          int(tokens[2 + 3 * index]),
                          int(tokens[3 + 3 * index])))
    intervals = []
    for center_x, center_y, radius in obstacles:
        distance = math.hypot(center_x, center_y)
        if distance < radius:
            return "100%\n"
        cosine = math.sqrt(max(0.0, distance * distance - radius * radius)) / distance
        half_angle = math.acos(min(1.0, cosine))
        middle_angle = math.atan2(center_y, center_x)
        left_angle = (middle_angle - half_angle) % FULL_CIRCLE
        right_angle = (middle_angle + half_angle) % FULL_CIRCLE
        if left_angle <= right_angle:
            intervals.append((left_angle, right_angle))
        else:
            intervals.append((0.0, right_angle))
            intervals.append((left_angle, FULL_CIRCLE))
    if not intervals:
        return "0%\n"
    intervals.sort()
    left_edge, right_edge = intervals[0]
    covered = 0.0
    for start, end in intervals[1:]:
        if start <= right_edge:
            if end > right_edge:
                right_edge = end
        else:
            covered += right_edge - left_edge
            left_edge, right_edge = start, end
    covered += right_edge - left_edge
    percentage = int(covered / FULL_CIRCLE * 100 + 0.5 + 1e-9)
    return str(percentage) + "%\n"


def ray_sweep(obstacles, rays=200000):
    blocked = 0
    for index in range(rays):
        angle = FULL_CIRCLE * (index + 0.5) / rays
        direction_x = math.cos(angle)
        direction_y = math.sin(angle)
        hidden = False
        for center_x, center_y, radius in obstacles:
            distance_squared = center_x * center_x + center_y * center_y
            if distance_squared < radius * radius:
                hidden = True
                break
            projection = center_x * direction_x + center_y * direction_y
            if projection <= 0:
                continue
            if distance_squared - projection * projection <= radius * radius:
                hidden = True
                break
        if hidden:
            blocked += 1
    return round(100 * blocked / rays)


SAMPLE = """1
2 2 2
"""
SAMPLE_OUT = "25%\n"
CASES = [
    ("1\n2 2 2\n", "25%\n"),
    ("1\n2 0 2\n", "50%\n"),
    ("1\n1 0 2\n", "100%\n"),
    ("1\n0 5 2\n", "13%\n"),
    ("0\n", "0%\n"),
]
assert oracle(SAMPLE) == SAMPLE_OUT
for text, expected in CASES:
    assert oracle(text) == expected
assert ray_sweep([(2, 2, 2)]) == 25
assert ray_sweep([(2, 0, 2)]) == 50
assert ray_sweep([(1, 0, 2)]) == 100
assert ray_sweep([(0, 5, 2)]) == 13


def write(name, obstacles):
    text = str(len(obstacles)) + "\n" + "".join(
        f"{center_x} {center_y} {radius}\n"
        for center_x, center_y, radius in obstacles)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0, 1), (2, 0, 2), (0, 5, 2)])
    rng = random.Random(20261126)
    wide = []
    for index in range(1000):
        angle = FULL_CIRCLE * index / 1000
        wide.append((round(500 * math.cos(angle)), round(500 * math.sin(angle)), 1000))
    write("3_wide", wide)
    random_obstacles = [(rng.randint(-5000, 5000), rng.randint(-5000, 5000),
                         rng.randint(1, 1000)) for _ in range(200)]
    write("4_random", random_obstacles)
    io_obstacles = [(rng.randint(-5000, 5000), rng.randint(-5000, 5000),
                     rng.randint(1, 1000)) for _ in range(1000)]
    write("5_io", io_obstacles)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
