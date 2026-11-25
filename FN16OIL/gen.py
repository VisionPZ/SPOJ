#!/usr/bin/env python3
from fractions import Fraction
from itertools import combinations
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def total_on_line(segments, anchor_x, anchor_y, slope):
    total = 0
    for left, right, depth in segments:
        cross = Fraction(anchor_x) + slope * (depth - anchor_y)
        if left <= cross <= right:
            total += right - left
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = tokens[cursor]
        cursor += 1
        segments = []
        for _ in range(count):
            first_end = tokens[cursor]
            second_end = tokens[cursor + 1]
            if first_end > second_end:
                first_end, second_end = second_end, first_end
            segments.append((first_end, second_end, tokens[cursor + 2]))
            cursor += 3
        best = max((right - left for left, right, _ in segments), default=0)
        points = [(point_x, depth) for left, right, depth in segments
                  for point_x in (left, right)]
        for (first_x, first_y), (second_x, second_y) in combinations(points, 2):
            if first_y == second_y:
                continue
            slope = Fraction(second_x - first_x, second_y - first_y)
            best = max(best, total_on_line(segments, first_x, first_y, slope))
        answers.append(str(best))
    return "\n".join(answers) + "\n"


def format_cases(cases):
    parts = []
    for segments in cases:
        parts.append(str(len(segments)))
        for left, right, depth in segments:
            parts.append(f"{left} {right} {depth}")
    return "\n".join(parts) + "\n"


SAMPLE = """5
100 180 20
30 60 30
70 110 40
10 40 50
0 80 70
3
50 60 10
-42 -42 20
25 0 10
"""
SAMPLE_OUT = """200
25
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 8 5\n") == "5\n"
assert oracle("2\n0 10 1\n20 30 2\n") == "20\n"
assert oracle("3\n0 4 1\n100 104 2\n8 12 3\n") == "8\n"
assert oracle("2\n-100 -50 7\n50 100 7\n") == "50\n"


def write(name, cases):
    text = format_cases(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[(5, 5, 1)], [(0, 0, 1), (10, 10, 2)],
                      [(-100, -50, 5), (50, 100, 5)],
                      [(0, 100, 1), (200, 300, 2), (-300, -200, 3)]])
    write("3_wide", [[(-1000000, 1000000, 1), (1, 2, 2), (999998, 1000000, 3)],
                     [(10, 500000, 1), (-500000, -10, 2), (100, 200, 3)]])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(10):
        depths = rng.sample(range(1, 200), rng.randint(1, 7))
        segments = []
        for depth in depths:
            left = rng.randint(-30, 30)
            segments.append((left, left + rng.randint(0, 20), depth))
        random_cases.append(segments)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(200):
        left = rng.randint(-50, 50)
        io_cases.append([(left, left + rng.randint(0, 15), 1)])
    write("5_io", io_cases)
    big_depths = list(range(1, 501))
    big_segments = []
    for depth in big_depths:
        left = rng.randint(-1000000, 1000000)
        big_segments.append((left, left + rng.randint(0, 1000000), depth))
    Path("/tmp/FN16OIL_big.txt").write_text(format_cases([big_segments]))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[(100, 180, 20), (30, 60, 30), (70, 110, 40),
                    (10, 40, 50), (0, 80, 70)],
                   [(50, 60, 10), (-42, -42, 20), (25, 0, 10)]])
build()
