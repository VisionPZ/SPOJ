#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def to_vector(latitude, longitude):
    lat = math.radians(latitude)
    lon = math.radians(longitude)
    horizontal = math.cos(lat)
    return (horizontal * math.cos(lon), horizontal * math.sin(lon), math.sin(lat))


def dot(first, second):
    return first[0] * second[0] + first[1] * second[1] + first[2] * second[2]


def cross(first, second):
    return (first[1] * second[2] - first[2] * second[1],
            first[2] * second[0] - first[0] * second[2],
            first[0] * second[1] - first[1] * second[0])


def unit(vector):
    length = math.sqrt(dot(vector, vector))
    return tuple(value / length for value in vector)


def on_arc(point, start, end, normal):
    return dot(cross(start, point), normal) >= -1e-9 and dot(cross(point, end), normal) >= -1e-9


def arrangement(rivers):
    points = []
    point_ids = {}

    def point_id(point):
        key = tuple(round(value * 1e9) for value in point)
        if key not in point_ids:
            point_ids[key] = len(points)
            points.append(point)
        return point_ids[key]

    starts = []
    ends = []
    normals = []
    for first_lat, first_lon, second_lat, second_lon, width in rivers:
        start = to_vector(first_lat, first_lon)
        end = to_vector(second_lat, second_lon)
        starts.append(start)
        ends.append(end)
        normals.append(unit(cross(start, end)))
        point_id(start)
        point_id(end)

    segments = []
    for index in range(len(rivers)):
        start = starts[index]
        end = ends[index]
        normal = normals[index]
        hits = {point_id(start)}
        for other in range(len(rivers)):
            if other == index:
                continue
            candidate_cross = cross(normal, normals[other])
            if math.sqrt(dot(candidate_cross, candidate_cross)) < 1e-12:
                continue
            for sign in (1, -1):
                candidate = unit(tuple(sign * value for value in candidate_cross))
                if on_arc(candidate, start, end, normal) and on_arc(candidate, starts[other], ends[other], normals[other]):
                    hits.add(point_id(candidate))
        hits.add(point_id(end))
        base = dot(start, end)
        direction = unit(tuple(end[axis] - base * start[axis] for axis in range(3)))
        ordered = sorted(hits, key=lambda identity: math.atan2(dot(points[identity], direction), dot(points[identity], start)))
        width = rivers[index][4]
        for segment_index in range(len(ordered) - 1):
            segments.append((width, ordered[segment_index], ordered[segment_index + 1]))
    return segments, len(points)


def brute_case(rivers):
    if not rivers:
        return 0
    if all(river[0] == 90 and river[2] == -90 for river in rivers):
        widths = sorted(river[4] for river in rivers)
        return sum(widths[:-1])
    segments, point_count = arrangement(rivers)
    best = None
    for removed_mask in range(1 << len(segments)):
        cost = 0
        parent = list(range(point_count))

        def find(node):
            while parent[node] != node:
                node = parent[node]
            return node

        remaining = 0
        for index, (weight, first, second) in enumerate(segments):
            if removed_mask & (1 << index):
                cost += weight
            else:
                remaining += 1
                first_root = find(first)
                second_root = find(second)
                if first_root != second_root:
                    parent[first_root] = second_root
        components = len({find(node) for node in range(point_count)})
        if remaining - point_count + components == 0:
            if best is None or cost < best:
                best = cost
    return best if best is not None else 0


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        river_count = int(tokens[cursor])
        cursor += 1
        rivers = []
        for _ in range(river_count):
            rivers.append(tuple(int(value) for value in tokens[cursor:cursor + 5]))
            cursor += 5
        answers.append(f"Case #{len(answers) + 1}: {brute_case(rivers)}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
2
90 0 -90 0 4
90 90 -90 90 1
3
90 0 -90 0 2
90 90 -90 90 4
90 180 -90 180 6
2
0 0 0 90 3
90 0 -90 0 5
"""
SAMPLE_OUT = """Case #1: 1
Case #2: 6
Case #3: 0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_case([(90, 0, -90, 0, 7)]) == 0
assert brute_case([(90, 0, -90, 0, 4), (90, 90, -90, 90, 1)]) == 1
assert brute_case([(90, 0, -90, 0, 2), (90, 90, -90, 90, 4), (90, 180, -90, 180, 6)]) == 6
assert brute_case([(0, 0, 0, 90, 3), (90, 0, -90, 0, 5)]) == 0


def write(name, cases):
    parts = [str(len(cases))]
    for rivers in cases:
        parts.append(str(len(rivers)))
        for river in rivers:
            parts.append(" ".join(str(value) for value in river))
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [(90, 0, -90, 0, 7)],
        [(0, 0, 0, 90, 3), (0, 180, 0, 270, 5)],
        [(90, 0, -90, 0, 9), (90, 90, -90, 90, 2)],
        [(0, 0, 90, 0, 4), (0, 90, -90, 90, 6)],
    ])
    rng = random.Random(20261126)
    wide_widths = [rng.randint(1, 1000000) for _ in range(500)]
    wide_rivers = [(90, index * 359 // 500, -90, index * 359 // 500, wide_widths[index]) for index in range(500)]
    write("3_wide", [wide_rivers])
    random_cases = []
    for _ in range(10):
        rivers = []
        for _ in range(rng.randint(2, 4)):
            rivers.append((rng.randint(-80, 80), rng.randint(0, 359),
                           rng.randint(-80, 80), rng.randint(0, 359),
                           rng.randint(1, 20)))
        random_cases.append(rivers)
    write("4_random", random_cases)
    io_cases = []
    for index in range(120):
        io_cases.append([(90, 0, -90, 0, (index % 7) + 1),
                         (90, 120, -90, 120, (index % 5) + 2)])
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
