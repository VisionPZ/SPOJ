#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
GRID = 10


def curve_point(index):
    time_value = index / GRID
    return math.sin(math.sqrt(time_value)), math.cos(time_value)


def oracle_case(center_x, center_y, radius, scan_limit=200000):
    for index in range(scan_limit + 1):
        time_value = index / GRID
        dx = math.sin(math.sqrt(time_value)) - center_x
        dy = math.cos(time_value) - center_y
        if dx * dx + dy * dy <= radius * radius:
            return index
    return None


def format_answer(index):
    if index is None:
        return "FAIL"
    return f"{index // GRID}.{index % GRID}"


def first_continuous_hit(center_x, center_y, radius, limit):
    step = 0.0001
    index = 0
    while index * step <= limit:
        time_value = index * step
        dx = math.sin(math.sqrt(time_value)) - center_x
        dy = math.cos(time_value) - center_y
        if dx * dx + dy * dy <= radius * radius:
            return time_value
        index += 1
    return None


def write_case(name, indices, radii):
    lines = [str(len(indices))]
    answers = []
    for index, radius in zip(indices, radii):
        center_x, center_y = curve_point(index)
        lines.append(f"{center_x:.12f} {center_y:.12f}")
        lines.append(f"{radius:.6f}")
        answers.append(format_answer(oracle_case(center_x, center_y, radius)))
    (ROOT / "in" / f"{name}.txt").write_text("\n".join(lines) + "\n")
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


SAMPLE_X, SAMPLE_Y = 0.744, 0.554
assert format_answer(oracle_case(SAMPLE_X, SAMPLE_Y, 0.01)) == "5.3"
assert math.hypot(math.sin(math.sqrt(5.3)) - SAMPLE_X, math.cos(5.3) - SAMPLE_Y) < 0.01
test_x, test_y = curve_point(1234)
assert format_answer(oracle_case(test_x, test_y, 0.0001)) == "123.4"
edge_x, edge_y = curve_point(77)
assert first_continuous_hit(edge_x, edge_y, 0.001, 7.7) <= 7.7
assert math.hypot(math.sin(math.sqrt(7.6)) - edge_x, math.cos(7.6) - edge_y) > 0.001

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

(ROOT / "in" / "1_sample.txt").write_text("1\n0.744 0.554\n0.01\n")
(ROOT / "out" / "1_sample.out").write_text("5.3\n")

write_case("2_edges", [0, 25, 31, 222, 1234, 10000], [0.0001] * 6)

wide_indices = [0, 1, 2, 250, 9999, 10000, 50000, 99999]
write_case("3_wide", wide_indices, [0.0001] * len(wide_indices))

rng = random.Random(20261125)
random_indices = [rng.randint(0, 100000) for _ in range(150)]
random_radii = [rng.choice([0.0001, 0.0002, 0.001, 0.01]) for _ in range(150)]
write_case("4_random", random_indices, random_radii)

io_indices = [(i * 7) % 10001 for i in range(150)]
write_case("5_io", io_indices, [0.0001] * 150)

print("generated five test pairs")
