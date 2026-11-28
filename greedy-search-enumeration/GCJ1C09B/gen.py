#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def solve_case(tokens, cursor):
    firefly_count = tokens[cursor]; cursor += 1
    position = [0, 0, 0]
    velocity = [0, 0, 0]
    for _ in range(firefly_count):
        for axis in range(3):
            position[axis] += tokens[cursor]; cursor += 1
        for axis in range(3):
            velocity[axis] += tokens[cursor]; cursor += 1
    cross = sum(position[axis] * velocity[axis] for axis in range(3))
    speed = sum(value * value for value in velocity)
    best_time = Fraction(0)
    if speed > 0 and cross < 0:
        best_time = Fraction(-cross, speed)
    squared = Fraction(0)
    for axis in range(3):
        along = (Fraction(position[axis]) + velocity[axis] * best_time) / firefly_count
        squared += along * along
    return math.sqrt(float(squared)), float(best_time), cursor


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for case_number in range(1, case_count + 1):
        distance, best_time, cursor = solve_case(tokens, cursor)
        answers.append(f"Case #{case_number}: {distance:.8f} {best_time:.8f}")
    return "\n".join(answers) + "\n"


SAMPLE = """3
3
3 0 -4 0 0 3
-3 -2 -1 3 0 0
-3 -1 2 0 3 0
3
-5 0 0 1 0 0
-7 0 0 1 0 0
-6 3 0 1 0 0
4
1 2 3 1 2 3
3 2 1 3 2 1
1 0 0 0 0 -1
0 10 0 0 -10 -1
"""
SAMPLE_OUT = """Case #1: 0.00000000 1.00000000
Case #2: 1.00000000 6.00000000
Case #3: 3.36340601 1.00000000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n1 0 0 0 0 0\n2 0 0 0 0 0\n3 0 0 0 0 0\n") == \
       "Case #1: 2.00000000 0.00000000\n"
assert oracle("1\n3\n1 0 0 1 0 0\n2 0 0 1 0 0\n3 0 0 1 0 0\n") == \
       "Case #1: 2.00000000 0.00000000\n"
assert oracle("1\n3\n0 0 0 -1 0 0\n0 1 0 -1 0 0\n0 -1 0 -1 0 0\n") == \
       "Case #1: 0.00000000 0.00000000\n"


def write(name, cases):
    lines = [str(len(cases))]
    for fireflies in cases:
        lines.append(str(len(fireflies)))
        for values in fireflies:
            lines.append(" ".join(str(value) for value in values))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    stationary = [(1, 0, 0, 0, 0, 0), (2, 0, 0, 0, 0, 0), (3, 0, 0, 0, 0, 0)]
    moving_away = [(1, 0, 0, 1, 0, 0), (2, 0, 0, 1, 0, 0), (3, 0, 0, 1, 0, 0)]
    crossing = [(0, 0, 0, -1, 0, 0), (0, 1, 0, -1, 0, 0), (0, -1, 0, -1, 0, 0)]
    write("2_edges", [stationary, moving_away, crossing])
    rng = random.Random(20261126)
    wide = []
    for _ in range(3):
        wide.append([tuple(rng.randint(-5000, 5000) for _ in range(6))
                     for _ in range(500)])
    write("3_wide", wide)
    cases = []
    for _ in range(40):
        size = rng.randint(3, 20)
        cases.append([tuple(rng.randint(-5000, 5000) for _ in range(6))
                      for _ in range(size)])
    write("4_random", cases)
    cases = []
    for _ in range(100):
        cases.append([tuple(rng.randint(-5000, 5000) for _ in range(6))
                      for _ in range(500)])
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_cases = [
    [(3, 0, -4, 0, 0, 3), (-3, -2, -1, 3, 0, 0), (-3, -1, 2, 0, 3, 0)],
    [(-5, 0, 0, 1, 0, 0), (-7, 0, 0, 1, 0, 0), (-6, 3, 0, 1, 0, 0)],
    [(1, 2, 3, 1, 2, 3), (3, 2, 1, 3, 2, 1), (1, 0, 0, 0, 0, -1),
     (0, 10, 0, 0, -10, -1)],
]
write("1_sample", sample_cases)
build()
