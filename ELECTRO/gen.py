#!/usr/bin/env python3
import heapq
import random
from fractions import Fraction
from math import gcd, hypot
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def direction(dx, dy):
    divisor = gcd(abs(dx), abs(dy))
    dx //= divisor
    dy //= divisor
    if dx < 0 or (dx == 0 and dy < 0):
        dx, dy = -dx, -dy
    return dx, dy


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def meet(line_a, line_b):
    determinant = line_a[0] * line_b[1] - line_b[0] * line_a[1]
    if determinant == 0:
        return None
    x = Fraction(line_a[2] * line_b[1] - line_b[2] * line_a[1], determinant)
    y = Fraction(line_a[0] * line_b[2] - line_b[0] * line_a[2], determinant)
    return x, y


def oracle(electrodes, start, target):
    if start == target:
        return 0.0
    boundary_lines = []
    all_lines = []
    for x1, y1, x2, y2 in electrodes:
        dx, dy = direction(x2 - x1, y2 - y1)
        first = dx * x1 + dy * y1
        second = dx * x2 + dy * y2
        low, high = min(first, second), max(first, second)
        boundary_lines.append((dx, dy, Fraction(low)))
        boundary_lines.append((dx, dy, Fraction(high)))
    extra_points = []
    for first_index in range(len(boundary_lines)):
        for second_index in range(first_index + 1, len(boundary_lines)):
            point = meet(boundary_lines[first_index], boundary_lines[second_index])
            if point is not None:
                extra_points.append(point)
    for x1, y1, x2, y2 in electrodes:
        dx, dy = direction(x2 - x1, y2 - y1)
        first = dx * x1 + dy * y1
        second = dx * x2 + dy * y2
        low, high = min(first, second), max(first, second)
        trials = {Fraction(low), Fraction(high), Fraction(dx * start[0] + dy * start[1]), Fraction(dx * target[0] + dy * target[1])}
        for point in extra_points:
            trials.add(dx * point[0] + dy * point[1])
        for offset in trials:
            if low <= offset <= high:
                all_lines.append((dx, dy, Fraction(offset)))
    lines = sorted(set(all_lines))
    if not lines:
        return None
    points = [start, target]
    for first_index in range(len(lines)):
        for second_index in range(first_index + 1, len(lines)):
            point = meet(lines[first_index], lines[second_index])
            if point is not None:
                points.append(point)
    unique_points = sorted(set(points))
    start_id = unique_points.index((Fraction(start[0]), Fraction(start[1])))
    target_id = unique_points.index((Fraction(target[0]), Fraction(target[1])))
    members = [[] for _ in lines]
    for point_id, point in enumerate(unique_points):
        for line_id, (dx, dy, offset) in enumerate(lines):
            if dx * point[0] + dy * point[1] == offset:
                members[line_id].append(point_id)
    adjacency = [[] for _ in unique_points]
    for line_id, (dx, dy, offset) in enumerate(lines):
        on_line = sorted(members[line_id], key=lambda index: (-dy * unique_points[index][0] + dx * unique_points[index][1]))
        for left, right in zip(on_line, on_line[1:]):
            first = unique_points[left]
            second = unique_points[right]
            weight = hypot(float(second[0] - first[0]), float(second[1] - first[1]))
            adjacency[left].append((right, weight))
            adjacency[right].append((left, weight))
    distances = [float("inf")] * len(unique_points)
    distances[start_id] = 0.0
    priority = [(0.0, start_id)]
    while priority:
        current, node = heapq.heappop(priority)
        if current > distances[node] + 1e-9:
            continue
        if node == target_id:
            break
        for neighbour, weight in adjacency[node]:
            candidate = current + weight
            if candidate < distances[neighbour] - 1e-9:
                distances[neighbour] = candidate
                heapq.heappush(priority, (candidate, neighbour))
    if distances[target_id] == float("inf"):
        return None
    return distances[target_id]


def format_answer(value):
    if value is None:
        return "Impossible"
    return f"{value:.5f}"


def oracle_text(cases):
    return "".join(f"Case {number}: {format_answer(oracle(electrodes, start, target))}\n"
                   for number, (electrodes, start, target) in enumerate(cases, 1))


def input_text(cases):
    parts = []
    for electrodes, start, target in cases:
        parts.append(str(len(electrodes)) + "\n")
        parts.append(" ".join(str(value) for value in start + target) + "\n")
        for electrode in electrodes:
            parts.append(" ".join(str(value) for value in electrode) + "\n")
    return "".join(parts) + "0\n"


SAMPLE_ELECTRODES = [(0, 0, 1, 0), (0, 1, 0, 2)]
SAMPLE_START = (2, 1)
SAMPLE_TARGET = (2, 2)
SAMPLE_CASES = [(SAMPLE_ELECTRODES, SAMPLE_START, SAMPLE_TARGET)]
SAMPLE_IN = input_text(SAMPLE_CASES)
SAMPLE_OUT = "Case 1: 3.00000\n"
assert abs(oracle(SAMPLE_ELECTRODES, SAMPLE_START, SAMPLE_TARGET) - 3.0) < 1e-9
assert oracle([], (0, 0), (0, 0)) == 0.0
assert oracle([], (0, 0), (0, 1)) is None
assert abs(oracle([(0, 0, 1, 0)], (0, 0), (0, 3)) - 3.0) < 1e-9
assert oracle([(0, 0, 1, 0)], (2, 0), (2, 3)) is None
assert oracle_text(SAMPLE_CASES) == SAMPLE_OUT


def write(name, cases):
    (ROOT / "in" / f"{name}.txt").write_text(input_text(cases))
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(cases))


def build():
    write("2_edges", [
        ([(0, 0, 1, 0)], (0, 0), (0, 0)),
        ([(0, 0, 1, 0)], (0, 0), (3, 0)),
        ([(0, 0, 1, 0)], (0, 0), (0, 3)),
        ([(0, 0, 0, 5)], (0, 0), (5, 0)),
        ([(0, 0, 1, 0), (0, 1, 0, 2)], (2, 1), (2, 2)),
    ])
    write("3_wide", [
        ([(0, 0, 100, 0), (0, 0, 0, 100), (0, 0, 100, 100)], (100, 0), (0, 100)),
        ([(10, 10, 20, 10), (10, 20, 10, 30), (0, 0, 30, 30)], (30, 10), (10, 30)),
    ])
    rng = random.Random(20261126)
    random_cases = []
    for number in range(12):
        count = rng.randint(1, 3)
        electrodes = []
        for _ in range(count):
            x1 = rng.randint(0, 10)
            y1 = rng.randint(0, 10)
            if rng.random() < 0.5:
                x2, y2 = x1 + rng.randint(1, 8), y1
            else:
                x2, y2 = x1, y1 + rng.randint(1, 8)
            electrodes.append((x1, y1, x2, y2))
        start = (rng.randint(0, 12), rng.randint(0, 12))
        target = (rng.randint(0, 12), rng.randint(0, 12))
        random_cases.append((electrodes, start, target))
    write("4_random", random_cases)
    io_cases = []
    for number in range(40):
        electrodes = [((number * 3) % 20, (number * 5) % 20, (number * 3) % 20 + 5, (number * 5) % 20),
                      ((number * 7) % 20, (number * 2) % 20, (number * 7) % 20, (number * 2) % 20 + 5)]
        start = (rng.randint(0, 20), rng.randint(0, 20))
        target = (rng.randint(0, 20), rng.randint(0, 20))
        io_cases.append((electrodes, start, target))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
