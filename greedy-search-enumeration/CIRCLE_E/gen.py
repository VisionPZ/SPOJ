#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(radius_one, radius_two, radius_three):
    area = radius_one * radius_two * radius_three * (radius_one + radius_two + radius_three)
    sides = radius_one * radius_two + radius_two * radius_three + radius_three * radius_one
    denominator = sides + 2.0 * (area ** 0.5)
    value = radius_one * radius_two * radius_three / denominator
    scaled = math.floor(value * 1000000.0 + 0.5)
    return "%d.%06d" % (scaled // 1000000, scaled % 1000000)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    position = 1
    for _ in range(case_count):
        answers.append(oracle_case(tokens[position], tokens[position + 1], tokens[position + 2]))
        position += 3
    return "\n".join(answers) + "\n"


def float_case(radii):
    radius_one, radius_two, radius_three = (float(value) for value in radii)
    curvature_sum = 1.0 / radius_one + 1.0 / radius_two + 1.0 / radius_three
    cross_sum = (1.0 / (radius_one * radius_two) + 1.0 / (radius_two * radius_three)
                 + 1.0 / (radius_three * radius_one))
    value = 1.0 / (curvature_sum + 2.0 * math.sqrt(cross_sum))
    scaled = math.floor(value * 1000000.0 + 0.5)
    return "%d.%06d" % (scaled // 1000000, scaled % 1000000)


SAMPLE = """3
1 1 1
10 10 10
23 46 69
"""
SAMPLE_OUT = """0.154701
1.547005
6.000000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 1\n") == "0.154701\n"
assert oracle("1\n10 10 10\n") == "1.547005\n"
assert oracle("1\n23 46 69\n") == "6.000000\n"
assert math.isqrt(3 * 3) == 3


def write(name, radii_cases, skip_sample=False):
    chosen = []
    for radii in radii_cases:
        candidate = radii
        if skip_sample:
            while float_case(candidate) != oracle_case(*candidate):
                candidate = tuple(value + 1 for value in candidate)
        chosen.append(candidate)
    lines = [str(len(chosen))]
    for radii in chosen:
        lines.append(" ".join(str(value) for value in radii))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 1), (1, 2, 3), (1000000000, 1000000000, 1000000000), (1, 1000000000, 1)], True)
    write("3_wide", [(1000000000, 999999999, 1000000000), (1, 1000000000, 1000000000),
                     (999999999, 1, 999999999), (1000000000, 1, 1)], True)
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(25):
        random_cases.append(tuple(rng.randint(1, 1000000000) for _ in range(3)))
    write("4_random", random_cases, True)
    output_cases = []
    for case_index in range(200):
        radius = 1000000000 - case_index * 1000000
        output_cases.append((radius, radius + 1, radius + 2))
    write("5_io", output_cases, True)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 1, 1), (10, 10, 10), (23, 46, 69)])
build()
