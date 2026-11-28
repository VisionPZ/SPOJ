#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def merge_intervals(intervals):
    ordered = sorted(intervals)
    merged = []
    for lower, upper in ordered:
        if lower >= upper:
            continue
        if merged and lower <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], upper))
        else:
            merged.append((lower, upper))
    return merged


def oracle(text):
    tokens = [int(value) for value in text.split()]
    panel_count = tokens[0]
    power = tokens[1]
    panels = [tuple(tokens[2 + 4 * index:6 + 4 * index]) for index in range(panel_count)]
    x_values = sorted({value for left_x, _, right_x, _ in panels for value in (left_x, right_x)})
    area = 0
    for strip_index in range(len(x_values) - 1):
        strip_start = x_values[strip_index]
        strip_end = x_values[strip_index + 1]
        active = [(bottom, top) for left_x, bottom, right_x, top in panels
                  if left_x <= strip_start and right_x >= strip_end]
        covered = sum(upper - lower for lower, upper in merge_intervals(active))
        area += (strip_end - strip_start) * covered
    return str(area * power) + "\n"


def brute_cells(panels, power):
    x_values = sorted({value for left_x, _, right_x, _ in panels for value in (left_x, right_x)})
    y_values = sorted({value for _, bottom, _, top in panels for value in (bottom, top)})
    area = 0
    for x_index in range(len(x_values) - 1):
        for y_index in range(len(y_values) - 1):
            middle_x = (x_values[x_index] + x_values[x_index + 1]) / 2
            middle_y = (y_values[y_index] + y_values[y_index + 1]) / 2
            if any(left_x <= middle_x < right_x and bottom <= middle_y < top
                   for left_x, bottom, right_x, top in panels):
                area += (x_values[x_index + 1] - x_values[x_index]) * (y_values[y_index + 1] - y_values[y_index])
    return str(area * power) + "\n"


SAMPLE = """3 2
-6 0 3 6
0 4 6 10
4 -2 9 6
"""
SAMPLE_OUT = """240
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n0 0 2 3\n") == "6\n"
assert oracle("2 2\n0 0 2 2\n1 1 3 3\n") == "14\n"
assert oracle("2 1\n0 0 0 5\n-1 -1 3 -1\n") == "0\n"
assert oracle("3 1\n-10 -10 10 10\n-5 -5 5 5\n0 0 1 1\n") == "400\n"
rng = random.Random(20261126)
for _ in range(300):
    panels = []
    for _ in range(rng.randint(1, 6)):
        left_x = rng.randint(-4, 4)
        right_x = rng.randint(left_x, 4)
        bottom = rng.randint(-4, 4)
        top = rng.randint(bottom, 4)
        panels.append((left_x, bottom, right_x, top))
    power = rng.randint(1, 4)
    text = str(len(panels)) + " " + str(power) + "\n"
    text += "".join(" ".join(str(value) for value in panel) + "\n" for panel in panels)
    assert oracle(text) == brute_cells(panels, power), panels


def write(name, panels, power):
    text = str(len(panels)) + " " + str(power) + "\n"
    text += "".join(" ".join(str(value) for value in panel) + "\n" for panel in panels)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_panel(limit):
    first_x = rng.randint(-limit, limit)
    second_x = rng.randint(-limit, limit)
    first_y = rng.randint(-limit, limit)
    second_y = rng.randint(-limit, limit)
    return (min(first_x, second_x), min(first_y, second_y),
            max(first_x, second_x), max(first_y, second_y))


def build():
    write("2_edges", [(0, 0, 0, 5), (-1, -1, 3, -1), (0, 0, 2, 2), (1, 1, 3, 3),
                      (-5, -5, 5, 5), (0, 0, 10, 10)], 3)
    write("3_wide", [random_panel(10**8) for _ in range(200)], 100)
    write("4_random", [random_panel(30) for _ in range(300)], 7)
    wide_panels = []
    for _ in range(100000):
        bottom = rng.randint(-10**8, 10**8 - 1)
        top = rng.randint(bottom + 1, 10**8)
        wide_panels.append((-10**8, bottom, 10**8, top))
    write("5_io", wide_panels, 100)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(-6, 0, 3, 6), (0, 4, 6, 10), (4, -2, 9, 6)], 2)
build()
