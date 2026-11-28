#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    distance = float(tokens[cursor]); cursor += 1
    offset = float(tokens[cursor]); cursor += 1
    height_a = float(tokens[cursor]); cursor += 1
    height_b = float(tokens[cursor]); cursor += 1
    error_limit = float(tokens[cursor]); cursor += 1
    left = -distance / 2.0
    right = distance / 2.0
    answers = []
    for number in range(1, count + 1):
        elevation_a = float(tokens[cursor]); cursor += 1
        elevation_b = float(tokens[cursor]); cursor += 1
        azimuth_a = float(tokens[cursor]); cursor += 1
        azimuth_b = float(tokens[cursor]); cursor += 1
        if not (0 < elevation_a < 90 and 0 < elevation_b < 90
                and 0 < azimuth_a < 90 and 90 < azimuth_b < 180):
            answers.append(f"{number} DISQUALIFIED")
            continue
        slope_a = math.tan(math.radians(elevation_a))
        slope_b = math.tan(math.radians(elevation_b))
        slope_azimuth_a = math.tan(math.radians(azimuth_a))
        slope_azimuth_b = math.tan(math.radians(azimuth_b))
        cross_x = (right * slope_azimuth_b - left * slope_azimuth_a) / (
            slope_azimuth_b - slope_azimuth_a)
        reach_a = (cross_x - left) / math.cos(math.radians(azimuth_a))
        reach_b = (cross_x - right) / math.cos(math.radians(azimuth_b))
        sight_a = height_a + reach_a * slope_a
        sight_b = height_b + reach_b * slope_b
        if abs(sight_a - sight_b) > error_limit:
            answers.append(f"{number} ERROR")
        else:
            answers.append(f"{number} {int((sight_a + sight_b) / 2.0 + 0.5)}")
    return "\n".join(answers) + "\n"


SAMPLE = """4
100.0 300.0 5.25 2.92 5.00
40.1 36.2 35.3 151.6
64.9 71.1 15.7 160.1
44.9 41.2 33.1 152.5
44.9 41.2 33.1 52.5
"""
SAMPLE_OUT = """1 50
2 ERROR
3 58
4 DISQUALIFIED
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n100 300 5 2 1\n45 45 45 135\n").startswith("1 ")
assert oracle("1\n100 300 5 2 1\n0 45 45 135\n") == "1 DISQUALIFIED\n"
assert oracle("1\n100 300 5 2 1\n45 45 45 45\n") == "1 DISQUALIFIED\n"
assert oracle("1\n100 300 5 2 1\n45 45 90 135\n") == "1 DISQUALIFIED\n"


def write(name, settings, shots):
    text = str(len(shots)) + "\n" + " ".join(str(value) for value in settings) + "\n"
    text += "".join(" ".join(str(value) for value in shot) + "\n" for shot in shots)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", (100, 300, 5.25, 2.92, 5), [
        (0, 45, 45, 135), (45, 0, 45, 135), (45, 45, 0, 135),
        (45, 45, 45, 90), (45, 45, 45, 180), (45, 45, 45, 135)])
    write("3_wide", (1000, 100000, 100, 100, 100000), [
        (10.0, 80.0, 30.0, 150.0), (80.0, 10.0, 30.0, 150.0),
        (80, 80, 80, 100), (20, 20, 20, 160)])
    rng = random.Random(20261126)
    shots = []
    for _ in range(120):
        elevation_a = rng.uniform(20, 70)
        elevation_b = rng.uniform(20, 70)
        azimuth_a = rng.uniform(10, 80)
        azimuth_b = 180.0 - azimuth_a + rng.uniform(-4, 4)
        azimuth_b = max(91.0, min(179.0, azimuth_b))
        shots.append((round(elevation_a, 3), round(elevation_b, 3),
                      round(azimuth_a, 3), round(azimuth_b, 3)))
    write("4_random", (250, 600, 8.5, 4.25, 8), shots)
    shots = [(40.1, 36.2, 35.3, 151.6) for _ in range(1000)]
    write("5_io", (100, 300, 5.25, 2.92, 5), shots)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", (100.0, 300.0, 5.25, 2.92, 5.00), [
    (40.1, 36.2, 35.3, 151.6), (64.9, 71.1, 15.7, 160.1),
    (44.9, 41.2, 33.1, 152.5), (44.9, 41.2, 33.1, 52.5)])
build()
