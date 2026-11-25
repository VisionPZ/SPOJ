#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def hypotenuse_by_legs(short_side, small_angle):
    other_leg = short_side / math.tan(math.radians(small_angle))
    return math.hypot(short_side, other_leg)


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    position = 1
    lines = []
    for case_index in range(1, case_count + 1):
        short_side = float(tokens[position])
        small_angle = float(tokens[position + 1])
        position += 2
        length = hypotenuse_by_legs(short_side, small_angle)
        lines.append("Case {}: {:.6f}".format(case_index, length))
    return "\n".join(lines) + "\n"


def direct_formula(text):
    tokens = text.split()
    case_count = int(tokens[0])
    position = 1
    lines = []
    for case_index in range(1, case_count + 1):
        short_side = float(tokens[position])
        small_angle = float(tokens[position + 1])
        position += 2
        length = short_side / math.sin(math.radians(small_angle))
        lines.append("Case {}: {:.6f}".format(case_index, length))
    return "\n".join(lines) + "\n"


SAMPLE = """3
7 30
15 30
10 18
"""
SAMPLE_OUT = """Case 1: 14.000000
Case 2: 30.000000
Case 3: 32.360680
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert direct_formula(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5 30\n") == "Case 1: 10.000000\n"
assert oracle("1\n9 45\n") == "Case 1: 12.727922\n"
assert math.isclose(hypotenuse_by_legs(10, 18), 10 / math.sin(math.radians(18)))


def write(name, pairs):
    text = "\n".join([str(len(pairs))] +
                     ["{} {}".format(side, angle) for side, angle in pairs]) + "\n"
    assert oracle(text) == direct_formula(text)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1.0, 30.0), (7.0, 90.0), (12.5, 45.0)])
    write("3_wide", [(1000000.0, 1.0), (999999.5, 89.5), (250000.25, 30.5)])
    rng = random.Random(20261126)
    pairs = [(rng.randint(1, 10000) / 10.0, rng.randint(10, 800) / 10.0)
             for _ in range(10)]
    write("4_random", pairs)
    write("5_io", [(rng.randint(1, 10000) / 10.0, rng.randint(10, 800) / 10.0)
                   for _ in range(10)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
