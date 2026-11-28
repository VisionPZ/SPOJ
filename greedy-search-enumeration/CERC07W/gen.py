#!/usr/bin/env python3
import math
import random
from pathlib import Path
from numpy.polynomial.legendre import leggauss

ROOT = Path(__file__).resolve().parent
GLASS_DENSITY = 2.5
PI = math.pi
NODES, WEIGHTS = leggauss(200)


def make_function(expression):
    def evaluate(x):
        return eval(expression, {"__builtins__": {}}, {"x": x})
    return evaluate


def gauss_integrate(function, lower, upper):
    midpoint = (lower + upper) / 2.0
    half_width = (upper - lower) / 2.0
    total = 0.0
    for node, weight in zip(NODES, WEIGHTS):
        total += weight * function(midpoint + half_width * node)
    return half_width * total


def oracle(cup_height, bottom_thickness, radius_text, thickness_text):
    radius = make_function(radius_text)
    thickness = make_function(thickness_text)
    inner = lambda x: radius(x) - thickness(x)
    outer_square = lambda x: radius(x) ** 2
    inner_square = lambda x: inner(x) ** 2

    full_area = gauss_integrate(outer_square, 0.0, cup_height)
    air_area = gauss_integrate(inner_square, bottom_thickness, cup_height)
    full_weight = GLASS_DENSITY * full_area
    air_weight = GLASS_DENSITY * air_area
    full_center = gauss_integrate(lambda x: x * outer_square(x), 0.0, cup_height) / full_area
    air_center = gauss_integrate(lambda x: x * inner_square(x), bottom_thickness, cup_height) / air_area
    glass_weight = full_weight - air_weight
    glass_center = (full_center * full_weight - air_center * air_weight) / glass_weight

    def combined(level):
        water_weight = gauss_integrate(inner_square, bottom_thickness, level)
        if water_weight <= 0.0:
            return glass_center
        water_center = gauss_integrate(lambda x: x * inner_square(x), bottom_thickness, level) / water_weight
        return (glass_center * glass_weight + water_center * water_weight) / (glass_weight + water_weight)

    low = bottom_thickness
    high = cup_height
    if glass_center < low:
        level = low
    elif combined(high) > high:
        level = high
    else:
        ratio = (math.sqrt(5.0) - 1.0) / 2.0
        left = high - ratio * (high - low)
        right = low + ratio * (high - low)
        for _ in range(100):
            if combined(left) < combined(right):
                high = right
                right = left
                left = high - ratio * (high - low)
            else:
                low = left
                left = right
                right = low + ratio * (high - low)
        level = (low + high) / 2.0

    liters = PI * gauss_integrate(inner_square, bottom_thickness, level) / 1000.0
    return f"Pour {liters:.3f} litres / {level - bottom_thickness:.3f} cm of water.\n"


SAMPLE = """9 1
3+x/6
17/8-x/8
10 1
(x+10)
10/(x+10)
0 0
"""
SAMPLE_OUT = """Pour 0.030 litres / 3.365 cm of water.
Pour 0.878 litres / 2.193 cm of water.
"""
assert oracle(9, 1, "3+x/6", "17/8-x/8") == "Pour 0.030 litres / 3.365 cm of water.\n"
assert oracle(10, 1, "(x+10)", "10/(x+10)") == "Pour 0.878 litres / 2.193 cm of water.\n"
assert oracle(2, 1, "2", "1") == "Pour 0.000 litres / 0.000 cm of water.\n"
assert oracle(5, 1, "4", "1+x/100") == oracle(5, 1, "2+2", "0.5+0.5+x/100")
assert GLASS_DENSITY == 2.5


def write(name, cups):
    lines = []
    answers = []
    for cup_height, bottom_thickness, radius_text, thickness_text in cups:
        lines.append(f"{cup_height} {bottom_thickness}")
        lines.append(radius_text)
        lines.append(thickness_text)
        answers.append(oracle(cup_height, bottom_thickness, radius_text, thickness_text).rstrip("\n"))
    lines.append("0 0")
    (ROOT / "in" / f"{name}.txt").write_text("\n".join(lines) + "\n")
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


def build():
    write("2_edges", [
        (2, 1, "2", "1"),
        (5, 1, "4", "1+x/100"),
        (20, 2, "5", "2"),
        (12, 3, "3+x/4", "1"),
    ])
    write("3_wide", [
        (100, 1, "80-x/4", "1+x/20"),
        (100, 10, "2+x/3", "1+x/100"),
        (50, 5, "20", "3+x/20"),
    ])
    rng = random.Random(20261126)
    radius_templates = ["3+x/6", "x+10", "5", "8-x/10", "2+x/3", "10-x/20"]
    thickness_templates = ["17/8-x/80", "10/(x+10)", "1", "2+x/100", "1+x/50", "0.5"]

    def valid(height, bottom, radius_text, thickness_text):
        radius = make_function(radius_text)
        thickness = make_function(thickness_text)
        for step in range(101):
            position = height * step / 100
            value = radius(position)
            if not 0.1 < value <= 100:
                return False
            if position >= bottom:
                thick = thickness(position)
                if not 0.1 <= thick < value:
                    return False
        return True

    def random_cup():
        while True:
            height = rng.randint(5, 60)
            bottom = rng.randint(1, height - 1)
            radius_text = rng.choice(radius_templates)
            thickness_text = rng.choice(thickness_templates)
            if valid(height, bottom, radius_text, thickness_text):
                return height, bottom, radius_text, thickness_text

    write("4_random", [random_cup() for _ in range(12)])
    write("5_io", [random_cup() for _ in range(25)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
