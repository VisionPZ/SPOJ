#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PI = math.acos(-1.0)


def volume(width, height, cut):
    position = min(height, max(0.0, cut))
    diameter = min(width, position)
    radius = diameter / 2.0
    circumference = PI * diameter
    best = 0.0
    if width >= circumference:
        best = max(best, PI * radius * radius * (height - position))
    if height - position >= circumference:
        best = max(best, PI * radius * radius * width)
    return best


def branch_limit(width, height, branch):
    low, high = 0.0, float(height)
    for _ in range(100):
        middle = (low + high) / 2.0
        diameter = min(width, middle)
        if branch == 1:
            feasible = width >= PI * diameter
        else:
            feasible = height - middle >= PI * diameter
        if feasible:
            low = middle
        else:
            high = middle
    return low


def oracle_case(width, height):
    best = 0.0
    for branch in (1, 2):
        boundary = branch_limit(width, height, branch)
        for delta in (-1e-11, 0.0):
            best = max(best, volume(width, height, boundary + delta))
    grid_step = height / 10000.0
    ranked = []
    for point_index in range(10001):
        cut = point_index * grid_step
        ranked.append((volume(width, height, cut), cut))
    ranked.sort(reverse=True)
    for _, center in ranked[:4]:
        low = max(0.0, center - grid_step)
        high = min(height, center + grid_step)
        for refine_index in range(201):
            cut = low + (high - low) * refine_index / 200.0
            best = max(best, volume(width, height, cut))
    return f"{best:.3f}"


def oracle(text):
    tokens = [int(value) for value in text.split()]
    answers = []
    for index in range(0, len(tokens) - 1, 2):
        width, height = tokens[index], tokens[index + 1]
        if width == 0 and height == 0:
            break
        answers.append(oracle_case(width, height))
    return "\n".join(answers) + "\n"


SAMPLE = """10 10
10 50
10 30
0 0
"""
SAMPLE_OUT = """54.247
785.398
412.095
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(1, 1) == "0.054"
assert oracle_case(5, 5) == "6.781"
assert oracle_case(1, 100) == "7.932"


def write(name, pairs):
    text = "".join(f"{width} {height}\n" for width, height in pairs) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [(1, 1), (1, 100), (100, 100), (2, 99)])
    write("3_wide", [(width, height) for width in range(1, 101) for height in (width, 100)])
    write("4_random", [tuple(sorted((rng.randint(1, 100), rng.randint(1, 100))))
                       for _ in range(40)])
    write("5_io", [tuple(sorted((rng.randint(1, 100), rng.randint(1, 100))))
                   for _ in range(120)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(10, 10), (10, 50), (10, 30)])
build()
