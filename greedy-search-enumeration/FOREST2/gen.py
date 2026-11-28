#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TWO_PI = 2.0 * math.pi
SAMPLE_STEPS = 2000


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while True:
        tree_count = tokens[cursor]
        cursor += 1
        if tree_count == 0:
            break
        trees = []
        for _ in range(tree_count):
            center_x = tokens[cursor]
            center_y = tokens[cursor + 1]
            radius = tokens[cursor + 2]
            cursor += 3
            distance = math.hypot(center_x, center_y)
            angle = math.atan2(center_y, center_x) % TWO_PI
            half = math.asin(radius / distance)
            trees.append((distance, angle, half, distance - radius))
        best = 0.0
        for index, (distance, angle, half, nearest) in enumerate(trees):
            visible = False
            for step in range(SAMPLE_STEPS + 1):
                sample_angle = angle - half + 2.0 * half * step / SAMPLE_STEPS
                blocked = False
                for other_distance, other_angle, other_half, _ in trees:
                    if other_distance >= distance - 1e-9:
                        continue
                    difference = (sample_angle - other_angle) % TWO_PI
                    if difference <= other_half + 1e-12 or difference >= TWO_PI - other_half - 1e-12:
                        blocked = True
                        break
                if not blocked:
                    visible = True
                    break
            if visible and nearest > best:
                best = nearest
        answers.append(f"{int(best * 1000 + 0.5) / 1000:.3f}")
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """3
10 10 11
1 1 1
-20 -10 20
5
1 2 2
-2 1 1
2 -1 1
-1 -2 2
10000 -10000 1000
0
"""
SAMPLE_OUT = """3.142
1.236
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 4 1\n0\n") == "4.000\n"
assert oracle("1\n1 1 1\n0\n") == "0.414\n"
assert oracle("2\n10 0 2\n3 4 2\n0\n") == "8.000\n"
assert math.asin(0.5) > 0.5


def format_case(cases):
    blocks = []
    for trees in cases:
        blocks.append(str(len(trees)) + "\n" + "".join(
            f"{center_x} {center_y} {radius}\n" for center_x, center_y, radius in trees))
    return "".join(blocks) + "0\n"


def write(name, cases):
    text = format_case(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_trees(rng, tree_count, radius_limit):
    trees = []
    attempts = 0
    while len(trees) < tree_count and attempts < 200000:
        attempts += 1
        center_x = rng.randint(-9000, 9000)
        center_y = rng.randint(-9000, 9000)
        radius = rng.randint(1, radius_limit)
        distance = math.hypot(center_x, center_y)
        if distance <= radius + 50:
            continue
        if any(math.hypot(center_x - other_x, center_y - other_y) <= radius + other_radius + 20
               for other_x, other_y, other_radius in trees):
            continue
        trees.append((center_x, center_y, radius))
    return trees


def build():
    write("2_edges", [
        [(3, 4, 1)],
        [(10, 0, 2), (20, 0, 2)],
        [(0, 10, 3), (0, 20, 3), (0, 30, 3)],
        [(-10, -1, 1), (-20, 0, 1)],
    ])
    rng = random.Random(20261127)
    wide_trees = []
    grid_radius = 100
    for row in range(-2, 3):
        for column in range(-2, 3):
            if column == 0 and row == 0:
                continue
            wide_trees.append((column * 3000 + 17, row * 3000 + 29, rng.randint(1, grid_radius)))
    write("3_wide", [wide_trees])
    random_cases = [random_trees(rng, rng.randint(2, 6), 400) for _ in range(6)]
    write("4_random", random_cases)
    io_cases = []
    for _ in range(140):
        count = rng.randint(1, 3)
        io_cases.append(random_trees(rng, count, 600))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    [(10, 10, 11), (1, 1, 1), (-20, -10, 20)],
    [(1, 2, 2), (-2, 1, 1), (2, -1, 1), (-1, -2, 2), (10000, -10000, 1000)],
])
build()
