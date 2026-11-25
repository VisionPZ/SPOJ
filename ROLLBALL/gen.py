#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = []
    for line in text.splitlines():
        parts = line.split()
        if len(parts) != 3:
            continue
        center_radius, ball_radius, degrees = map(int, parts)
        sine = math.sin(math.radians(degrees))
        cosine = math.cos(math.radians(degrees))
        ratio = center_radius / ball_radius
        radial_spin = 2.5 * ratio * sine
        vertical_spin = 1.0 + ratio * (1.0 + 2.5 * sine * sine) / cosine
        cross_product = radial_spin * sine - vertical_spin * cosine
        vector_length = math.hypot(radial_spin, vertical_spin)
        circle_radius = ball_radius * abs(cross_product) / vector_length
        lines.append(str(math.floor(circle_radius + 0.5)))
    return "\n".join(lines) + "\n"


def write(name, lines):
    text = "\n".join(" ".join(map(str, triple)) for triple in lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = "220000 100 29\n"
SAMPLE_OUT = "46\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1000000 100 45\n") == "27\n"
assert oracle("100 100 30\n") == "59\n"
assert oracle("1000000 1 89\n") == "0\n"


def build():
    write("2_edges", [
        (2, 1, 1), (100, 1, 89), (1000000, 1000, 1),
        (1000000, 1000, 89), (3, 2, 45), (1000, 3, 60),
    ])
    wide = []
    for index in range(20):
        wide.append((1000000 - index * 997, 1 + index * 37, 1 + index * 4))
    write("3_wide", wide)
    rng = random.Random(20261126)
    write("4_random", [
        (rng.randint(2, 1000000), rng.randint(1, 1000), rng.randint(1, 89))
        for _ in range(60)
    ])
    write("5_io", [
        (rng.randint(2, 1000000), rng.randint(1, 1000), rng.randint(1, 89))
        for _ in range(45000)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
