#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE_COUNT = 4000


def sample_sphere(center, radius):
    points = [center]
    golden_angle = math.pi * (3.0 - math.sqrt(5.0))
    for index in range(SAMPLE_COUNT):
        vertical = 1.0 - 2.0 * (index + 0.5) / SAMPLE_COUNT
        ring_radius = math.sqrt(max(0.0, 1.0 - vertical * vertical))
        angle = golden_angle * index
        points.append((center[0] + radius * ring_radius * math.cos(angle),
                       center[1] + radius * ring_radius * math.sin(angle),
                       center[2] + radius * vertical))
    return points


def oracle_case(star, moon, planet):
    star_center = star[:3]
    star_radius = star[3]
    moon_center = moon[:3]
    moon_radius = moon[3]
    planet_center = planet[:3]
    planet_radius = planet[3]
    axis = [moon_center[i] - star_center[i] for i in range(3)]
    center_distance = math.sqrt(sum(value * value for value in axis))
    unit = [value / center_distance for value in axis]
    relative = [planet_center[i] - moon_center[i] for i in range(3)]
    axial = sum(relative[i] * unit[i] for i in range(3))
    sideways_vec = [relative[i] - axial * unit[i] for i in range(3)]
    sideways = math.sqrt(sum(value * value for value in sideways_vec))
    pen_slope = (star_radius + moon_radius) / center_distance
    pen_radius = moon_radius + axial * pen_slope
    if star_radius > moon_radius:
        apex = moon_radius * center_distance / (star_radius - moon_radius)
        umb_slope = -(star_radius - moon_radius) / center_distance
    else:
        apex = float('inf')
        umb_slope = (moon_radius - star_radius) / center_distance
    umb_radius = moon_radius + umb_slope * axial

    labels = []
    for point in sample_sphere(planet_center, planet_radius):
        point_rel = [point[i] - moon_center[i] for i in range(3)]
        point_axial = sum(point_rel[i] * unit[i] for i in range(3))
        point_sideways_vec = [point_rel[i] - point_axial * unit[i] for i in range(3)]
        point_sideways = math.sqrt(sum(value * value for value in point_sideways_vec))
        total = False
        partial = False
        if point_axial > 0:
            if point_sideways <= pen_radius + 1e-9:
                partial = True
            inside_umb = moon_radius + umb_slope * point_axial
            if point_sideways <= inside_umb + 1e-9 and point_axial <= apex + 1e-9:
                total = True
        labels.append(2 if total else (1 if partial else 0))

    if all(label == 2 for label in labels):
        return "Entire total solar eclipse"
    if any(label == 2 for label in labels):
        return "Part total solar eclipse"
    if all(label >= 1 for label in labels):
        return "Entire partial solar eclipse"
    if any(label >= 1 for label in labels):
        return "Part partial solar eclipse"
    return "No solar eclipse"


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    answers = []
    for index in range(0, len(lines) - 2, 3):
        if lines[index].strip() == "-1":
            break
        star = tuple(map(int, lines[index].split()))
        moon = tuple(map(int, lines[index + 1].split()))
        planet = tuple(map(int, lines[index + 2].split()))
        answers.append(oracle_case(star, moon, planet))
    return "\n".join(answers) + "\n"


SAMPLE_IN = """0 0 0 700
49900 1000 149700 2
50000 1000 150000 7
0 0 0 10
50 0 100 40
60 0 200 1
-1
"""
SAMPLE_OUT = """Part total solar eclipse
Entire total solar eclipse
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("0 0 0 1\n100 0 0 1\n200 0 0 1\n-1\n") == "Entire total solar eclipse\n"
assert oracle("0 0 0 100\n100 0 0 1\n200 0 0 1\n-1\n") == "Entire partial solar eclipse\n"
assert oracle("0 0 0 100\n100 0 0 1\n200 60 0 1\n-1\n") == "Entire partial solar eclipse\n"
assert oracle("0 0 0 100\n100 0 0 1\n200 200 0 1\n-1\n") == "No solar eclipse\n"


def write(name, cases):
    lines = []
    for star, moon, planet in cases:
        lines.append(" ".join(map(str, star)))
        lines.append(" ".join(map(str, moon)))
        lines.append(" ".join(map(str, planet)))
    lines.append("-1")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def aligned_case(rng, distance, moon_radius, planet_radius, offset):
    star_radius = rng.randint(40, 900)
    moon = (distance, 0, 0, moon_radius)
    planet = (distance + rng.randint(60, 200), offset, 0, planet_radius)
    return ((0, 0, 0, star_radius), moon, planet)


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        ((0, 0, 0, 5), (20, 0, 0, 1), (40, 0, 0, 1)),
        ((0, 0  , 0, 500), (1000, 0, 0, 5), (1200, 0, 0, 3)),
        ((0, 0, 0, 500), (1000, 0, 0, 5), (1200, 300, 0, 3)),
        ((0, 0, 0, 500), (1000, 0, 0, 5), (500, 0, 0, 3)),
    ])
    write("3_wide", [
        ((0, 0, 0, 1000000), (1000000000, 0, 0, 10000),
         (1000000000 + 20000, 0, 0, 100)),
        ((0, 0, 0, 1000000), (1000000000, 0, 0, 10000),
         (1000000000 + 20000, 30000, 0, 100)),
        ((10, 20, 30, 800000), (900000000, 20, 30, 20000),
         (900000000 + 30000, 20, 30, 200)),
    ])
    cases = []
    for _ in range(30):
        cases.append(aligned_case(rng, rng.randint(200, 4000),
                                  rng.randint(1, 20), rng.randint(1, 12),
                                  rng.choice([0, 0, 2, 5, 10, 20, 40])))
    write("4_random", cases)
    io_cases = []
    for _ in range(80):
        io_cases.append(aligned_case(rng, rng.randint(300, 5000),
                                     rng.randint(1, 30), rng.randint(1, 15),
                                     rng.choice([0, 0, 3, 8, 15, 30])))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
