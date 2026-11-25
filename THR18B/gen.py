#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    dart_count = tokens[0]
    total = 0
    for shot_index in range(dart_count):
        x_coord = tokens[1 + 2 * shot_index]
        y_coord = tokens[2 + 2 * shot_index]
        distance = math.hypot(x_coord, y_coord)
        score = 0
        for radius in range(10, 200, 20):
            if distance <= radius:
                score = (210 - radius) // 20
                break
        total += score
    return str(total) + "\n"


SAMPLE = """2
4 7
-31 -5
"""
SAMPLE_OUT = """18
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n12 -16\n-180 100\n152 10\n") == "11\n"
assert oracle("1\n0 0\n") == "10\n"
assert oracle("1\n300 300\n") == "0\n"
assert oracle("2\n10 0\n30 0\n") == "19\n"


def write(name, shots):
    text = str(len(shots)) + "\n"
    for x_coord, y_coord in shots:
        text += f"{x_coord} {y_coord}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0), (300, -300)])
    write("3_wide", [(radius, 0) for radius in range(0, 200, 10)] * 5)
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(-300, 300), rng.randint(-300, 300)) for _ in range(100)])
    write("5_io", [(0, 0)] * 100)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, 7), (-31, -5)])
build()
