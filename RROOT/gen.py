#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PANELS = 20000


def topped_area(half_side):
    if half_side <= 0:
        return 0.0
    reach = min(half_side, math.sqrt(half_side))
    width = 2.0 * reach / PANELS
    total = half_side - reach * reach
    for panel in range(1, PANELS):
        offset = -reach + panel * width
        total += 4.0 * (half_side - offset * offset) if panel % 2 else 2.0 * (half_side - offset * offset)
    total += half_side - reach * reach
    return total * width / 3.0


def oracle(text):
    tokens = [int(value) for value in text.split()]
    lines = []
    for side in tokens[1:]:
        half_side = side / 2.0
        total_area = 4.0 * half_side * half_side
        bad_probability = topped_area(half_side) / total_area if total_area else 0.0
        lines.append(f"{1.0 - bad_probability:.6f}")
    return "\n".join(lines) + "\n"


SAMPLE = "1\n8\n"
SAMPLE_OUT = "0.833333\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "0.666667\n"
assert oracle("1\n1\n") == "0.583333\n"
assert oracle("1\n200\n") == "0.966667\n"
assert oracle("1\n1000000\n") == "0.999529\n"
assert math.isclose(topped_area(4.0), 32.0 / 3.0, rel_tol=1e-12)


def write(name, sides):
    text = str(len(sides)) + "\n" + "\n".join(str(value) for value in sides) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 7])
    write("3_wide", [999999, 1000000, 1000000, 999998])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000) for _ in range(24)])
    write("5_io", [rng.randint(1, 1000000) for _ in range(24)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [8])
build()
