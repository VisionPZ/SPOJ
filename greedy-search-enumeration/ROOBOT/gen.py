#!/usr/bin/env python3
import math
import random
from collections import defaultdict
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = (("up", 0, 1), ("right", 1, 0), ("down", 0, -1), ("left", -1, 0))


def probabilities(text):
    tokens = text.split()
    move_count = int(tokens[0])
    values = [Fraction(token) for token in tokens[1:5]]
    return move_count, values


def format_number(value):
    scaled = math.floor(float(value) * 1000000 + 0.5)
    return f"{scaled // 1000000}.{scaled % 1000000:06d}"


def brute_force(text):
    move_count, (up, right, down, left) = probabilities(text)
    chance = (up, right, down, left)
    total = Fraction(0)
    for choices in range(4 ** move_count):
        state = choices
        path_chance = Fraction(1)
        min_x = max_x = min_y = max_y = 0
        current_x = current_y = 0
        for _ in range(move_count):
            direction = state % 4
            state //= 4
            path_chance *= chance[direction]
            _, delta_x, delta_y = DIRECTIONS[direction]
            current_x += delta_x
            current_y += delta_y
            min_x = min(min_x, current_x)
            max_x = max(max_x, current_x)
            min_y = min(min_y, current_y)
            max_y = max(max_y, current_y)
        total += path_chance * (max_x - min_x + max_y - min_y)
    return format_number(total) + "\n"


def axis_expectation(move_count, plus, minus, stay):
    below = {(0, 0): 1.0}
    above = {(0, 0): 1.0}
    for _ in range(move_count):
        next_below = defaultdict(float)
        next_above = defaultdict(float)
        for (position, lowest), chance in below.items():
            next_below[(position + 1, min(lowest, position + 1))] += chance * plus
            next_below[(position - 1, min(lowest, position - 1))] += chance * minus
            next_below[(position, lowest)] += chance * stay
        for (position, highest), chance in above.items():
            next_above[(position + 1, max(highest, position + 1))] += chance * plus
            next_above[(position - 1, max(highest, position - 1))] += chance * minus
            next_above[(position, highest)] += chance * stay
        below = next_below
        above = next_above
    low_sum = sum(chance * lowest for (_, lowest), chance in below.items())
    high_sum = sum(chance * highest for (_, highest), chance in above.items())
    return high_sum - low_sum


def absolute_dp(text):
    move_count, values = probabilities(text)
    up, right, down, left = (float(value) for value in values)
    horizontal = axis_expectation(move_count, right, left, up + down)
    vertical = axis_expectation(move_count, up, down, right + left)
    return format_number(horizontal + vertical) + "\n"


def oracle(text):
    move_count, _ = probabilities(text)
    if move_count <= 8:
        return brute_force(text)
    return absolute_dp(text)


SAMPLE_ONE = """2
0.100000 0.200000 0.300000 0.400000
"""
SAMPLE_ONE_OUT = """1.780000
"""
SAMPLE_TWO = """3
0.25 0.25 0.25 0.25
"""
assert brute_force(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert brute_force(SAMPLE_TWO) == "2.375000\n"
assert brute_force("1\n1.0 0.0 0.0 0.0\n") == "1.000000\n"
assert brute_force("2\n0.0 1.0 0.0 0.0\n") == "2.000000\n"
assert brute_force("2\n0.0 0.0 0.0 1.0\n") == "2.000000\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1\n0.000000 1.000000 0.000000 0.000000\n")
    write("3_wide", "200\n0.250000 0.250000 0.250000 0.250000\n")
    rng = random.Random(20261126)
    parts = []
    for _ in range(6):
        step = rng.randint(1, 8)
        weights = [rng.randint(0, 1000000) for _ in range(4)]
        total = sum(weights)
        values = [f"{weight / total:.6f}" for weight in weights]
        values[-1] = f"{1.0 - sum(float(value) for value in values[:-1]):.6f}"
        parts.append(f"{step}\n{' '.join(values)}\n")
    write("4_random", "".join(parts))
    write("5_io", "200\n0.333333 0.333333 0.166667 0.166667\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_ONE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_ONE_OUT)
build()
