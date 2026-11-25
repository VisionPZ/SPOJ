#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3 10\n1 7 12\n"
SAMPLE_OUTPUT = "7\n"
SECOND_INPUT = "2 0\n11 -10\n"
SECOND_OUTPUT = "10\n"
THIRD_INPUT = "5 0\n0 0 1000 0 0\n"
THIRD_OUTPUT = "0\n"


def parse_case(text):
    tokens = text.split()
    point_count = int(tokens[0])
    start = int(tokens[1])
    points = [int(token) for token in tokens[2:2 + point_count]]
    return point_count, start, points


def route_distance(start, left_end, right_end):
    go_left_first = abs(start - left_end) + abs(right_end - left_end)
    go_right_first = abs(start - right_end) + abs(right_end - left_end)
    return min(go_left_first, go_right_first)


def solve_case(point_count, start, points):
    if point_count <= 1:
        return 0
    ordered = sorted(points)
    best = None
    for skipped in range(point_count):
        if skipped == 0:
            left_end = ordered[1]
        else:
            left_end = ordered[0]
        if skipped == point_count - 1:
            right_end = ordered[point_count - 2]
        else:
            right_end = ordered[point_count - 1]
        distance = route_distance(start, left_end, right_end)
        if best is None or distance < best:
            best = distance
    return best


def oracle(text):
    point_count, start, points = parse_case(text)
    return str(solve_case(point_count, start, points)) + "\n"


def brute_force(point_count, start, points):
    from itertools import combinations
    best = None
    for kept in combinations(points, point_count - 1):
        if not kept:
            candidate = 0
        else:
            candidate = route_distance(start, min(kept), max(kept))
        if best is None or candidate < best:
            best = candidate
    return best


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle(SECOND_INPUT) == SECOND_OUTPUT
assert oracle(THIRD_INPUT) == THIRD_OUTPUT
assert oracle("1 0\n42\n") == "0\n"
assert oracle("2 0\n-1000000 1000000\n") == "1000000\n"
assert all(solve_case(size, start, points) == brute_force(size, start, points)
           for size, start, points in [(4, 0, [5, -3, 8, 1]), (5, 6, [0, 0, 4, 9, 2]),
                                       (3, 11, [1, 7, 12]), (6, -2, [-8, -1, 0, 3, 7, 9])])


def write(name, point_count, start, points):
    input_text = f"{point_count} {start}\n" + " ".join(str(value) for value in points) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace():
    point_count, start, points = parse_case(SAMPLE_INPUT)
    ordered = sorted(points)
    print(f"start {start}, sorted points {ordered}")
    for skipped in range(point_count):
        if skipped == 0:
            left_end, right_end = ordered[1], ordered[-1]
        elif skipped == point_count - 1:
            left_end, right_end = ordered[0], ordered[-2]
        else:
            left_end, right_end = ordered[0], ordered[-1]
        print(f"skip {ordered[skipped]}: range {left_end} to {right_end}, "
              f"left first {abs(start - left_end) + abs(right_end - left_end)}, "
              f"right first {abs(start - right_end) + abs(right_end - left_end)}")
    print("minimum", solve_case(point_count, start, points))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", 3, 10, [1, 7, 12])
        write("2_edges", 2, 0, [11, -10])
        random.seed(2026)
        wide_points = [random.randint(-1000000, 1000000) for _ in range(100000)]
        write("3_wide", 100000, 0, wide_points)
        random_points = [random.randint(-1000000, 1000000) for _ in range(100000)]
        write("4_random", 100000, random.randint(-1000000, 1000000), random_points)
        extreme_points = [-1000000] * 50000 + [1000000] * 50000
        write("5_io", 100000, 0, extreme_points)
