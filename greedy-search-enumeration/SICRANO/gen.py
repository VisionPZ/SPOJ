#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    test_count = tokens[pos]
    pos += 1
    lines = []
    for _ in range(test_count):
        point_count = tokens[pos]
        segment_count = tokens[pos + 1]
        pos += 2
        points = []
        for _ in range(point_count):
            points.append((tokens[pos], tokens[pos + 1]))
            pos += 2
        for _ in range(segment_count):
            start_x, start_y = tokens[pos], tokens[pos + 1]
            end_x, end_y = tokens[pos + 2], tokens[pos + 3]
            pos += 4
            delta_x = end_x - start_x
            delta_y = end_y - start_y
            length_squared = delta_x * delta_x + delta_y * delta_y
            hits = 0
            for point_x, point_y in points:
                if length_squared == 0:
                    if point_x == start_x and point_y == start_y:
                        hits += 1
                    continue
                offset_x = point_x - start_x
                offset_y = point_y - start_y
                fraction = (offset_x * delta_x + offset_y * delta_y) / length_squared
                if fraction < -1e-9 or fraction > 1 + 1e-9:
                    continue
                miss_x = offset_x - fraction * delta_x
                miss_y = offset_y - fraction * delta_y
                if miss_x * miss_x + miss_y * miss_y < 1e-9:
                    hits += 1
            lines.append(str(hits))
    return "\n".join(lines) + "\n" if lines else ""


SAMPLE = """1
4 3
1 1
2 2
3 3
4 4
0 0 5 5
3 3 4 4
0 0 1 0
"""
SAMPLE_OUT = """4
2
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 1\n5 5\n5 5\n0 0 10 10\n") == "2\n"
assert oracle("1\n3 1\n0 0\n5 0\n10 0\n0 0 10 0\n") == "3\n"
assert oracle("1\n3 1\n0 0\n0 5\n0 10\n0 0 0 10\n") == "3\n"
assert oracle("1\n1 1\n1 2\n0 0 10 0\n") == "0\n"


def write_case(name, cases):
    text = str(len(cases)) + "\n"
    for points, segments in cases:
        text += f"{len(points)} {len(segments)}\n"
        for point_x, point_y in points:
            text += f"{point_x} {point_y}\n"
        for segment in segments:
            text += " ".join(str(value) for value in segment) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    points = [(0, 0), (5, 5), (5, 5), (10, 0), (2, 3)]
    segments = [(0, 0, 10, 10), (0, 0, 10, 0), (10, 0, 0, 10), (2, 3, 2, 3)]
    write_case("2_edges", [(points, segments)])
    rng = random.Random(20261126)
    wide_points = [(rng.randint(0, 100), rng.randint(0, 100)) for _ in range(50)]
    wide_segments = []
    for _ in range(50):
        first_x, first_y = rng.randint(0, 100), rng.randint(0, 100)
        second_x, second_y = rng.randint(0, 100), rng.randint(0, 100)
        wide_segments.append((first_x, first_y, second_x, second_y))
    write_case("3_wide", [(wide_points, wide_segments)])
    random_cases = []
    for _ in range(5):
        case_points = [(rng.randint(0, 100), rng.randint(0, 100)) for _ in range(rng.randint(1, 50))]
        case_segments = []
        for _ in range(rng.randint(1, 50)):
            first_x, first_y = rng.randint(0, 100), rng.randint(0, 100)
            second_x, second_y = rng.randint(0, 100), rng.randint(0, 100)
            case_segments.append((first_x, first_y, second_x, second_y))
        random_cases.append((case_points, case_segments))
    write_case("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        case_points = [(rng.randint(0, 100), rng.randint(0, 100)) for _ in range(50)]
        case_segments = []
        for _ in range(50):
            first_x, first_y = rng.randint(0, 100), rng.randint(0, 100)
            second_x, second_y = rng.randint(0, 100), rng.randint(0, 100)
            case_segments.append((first_x, first_y, second_x, second_y))
        io_cases.append((case_points, case_segments))
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_points = [(1, 1), (2, 2), (3, 3), (4, 4)]
sample_segments = [(0, 0, 5, 5), (3, 3, 4, 4), (0, 0, 1, 0)]
write_case("1_sample", [(sample_points, sample_segments)])
build()
