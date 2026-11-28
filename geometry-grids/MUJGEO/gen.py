#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [float(value) for value in text.split()]
    angle_a, angle_b, side_bc, side_ad = values[:4]
    radians_a = math.radians(angle_a)
    radians_b = math.radians(angle_b)
    radians_c = math.pi - radians_a - radians_b
    side_ac = side_bc * math.sin(radians_b) / math.sin(radians_a)
    point_dx = side_ad * math.cos(radians_c)
    point_dy = side_ad * math.sin(radians_c)
    chord_squared = (side_ac - point_dx) ** 2 + point_dy ** 2
    circle_area = math.pi * chord_squared / 4.0
    return f"{circle_area:.10f}\n"


SAMPLE = """10 30 40 50
"""
SAMPLE_OUT = """19311.6239189261
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("60 60 1 1\n") == "0.7853981634\n"
assert oracle("30 60 2 2\n") == "12.5663706144\n"
assert oracle("90 45 1 1\n") == "0.3926990817\n"
assert math.isclose(math.pi / 4, 0.7853981633974483, rel_tol=1e-15)


def write(name, angle_a, angle_b, side_bc, side_ad):
    text = f"{angle_a} {angle_b} {side_bc} {side_ad}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 89.5, 45.25, 1, 1)
    write("3_wide", 2, 3, 100, 100)
    rng = random.Random(20261126)
    for index in range(3):
        angle_a = rng.uniform(1, 100)
        angle_b = rng.uniform(1, 179 - angle_a)
        write(f"4_random_{index}", round(angle_a, 6), round(angle_b, 6),
              rng.randint(1, 30), rng.randint(1, 30))
    write("5_io", 170, 5, 100, 100)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 10, 30, 40, 50)
build()
