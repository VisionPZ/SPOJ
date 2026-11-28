#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def triangle_area(first, second, diagonal):
    semiperimeter = (first + second + diagonal) / 2.0
    squared = semiperimeter * (semiperimeter - first) * (semiperimeter - second) * (semiperimeter - diagonal)
    return math.sqrt(max(0.0, squared))


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        sides = [float(value) for value in tokens[cursor:cursor + 4]]
        cursor += 4
        first, second, third, fourth = sides
        low = max(abs(first - second), abs(third - fourth))
        high = min(first + second, third + fourth)
        for _ in range(200):
            left = low + (high - low) / 3.0
            right = high - (high - low) / 3.0
            if triangle_area(first, second, left) + triangle_area(third, fourth, left) < triangle_area(first, second, right) + triangle_area(third, fourth, right):
                low = left
            else:
                high = right
        diagonal = (low + high) / 2.0
        area = triangle_area(first, second, diagonal) + triangle_area(third, fourth, diagonal)
        answers.append(f"{area:.2f}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
1 2 1 2
0.5 0.5 0.5 0.5
"""
SAMPLE_OUT = """2.00
0.25
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 1 1\n") == "1.00\n"
assert oracle("1\n3 4 5 6\n") == f"{math.sqrt((9 - 3) * (9 - 4) * (9 - 5) * (9 - 6)):.2f}\n"
assert oracle("2\n2 2 2 2\n1 2 3 3.5\n") == "4.00\n4.75\n"


def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(" ".join(f"{side:.3f}" for side in case) for case in cases)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def valid_case(rng):
    while True:
        sides = [round(rng.uniform(0.1, 1000.0), 3) for _ in range(4)]
        if 2 * max(sides) < sum(sides):
            return sides


def build():
    write("2_edges", [[1.0, 1.0, 1.0, 1.0], [0.1, 0.1, 0.1, 0.1], [999.999, 999.999, 999.999, 999.999]])
    write("3_wide", [[1000.0, 1000.0, 1000.0, 1000.0], [1.0, 2.0, 3.0, 3.9], [500.0, 500.0, 1.0, 1.0]])
    rng = random.Random(20261126)
    write("4_random", [valid_case(rng) for _ in range(20)])
    write("5_io", [valid_case(rng) for _ in range(2000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
