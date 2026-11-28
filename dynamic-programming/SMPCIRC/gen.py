#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    answers = []
    for first_x, first_y, first_r, second_x, second_y, second_r in cases:
        distance = math.hypot(first_x - second_x, first_y - second_y)
        large = max(first_r, second_r)
        small = min(first_r, second_r)
        if distance + small < large - 1e-9:
            answers.append("I")
        elif abs(distance + small - large) <= 1e-9:
            answers.append("E")
        else:
            answers.append("O")
    return "\n".join(answers) + "\n"


def write(name, cases):
    lines = [str(len(cases))]
    lines.extend(" ".join(str(value) for value in case) for case in cases)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


SAMPLE = [(103, 104, 5, 100, 100, 10), (103, 104, 10, 100, 100, 10)]
assert oracle(SAMPLE) == "E\nO\n"
assert oracle([(100, 100, 3, 100, 100, 10)]) == "I\n"
assert oracle([(100, 100, 10, 103, 104, 5)]) == "E\n"
assert oracle([(100, 100, 2, 110, 100, 3)]) == "O\n"
assert oracle([(100, 100, 7, 100, 100, 7)]) == "E\n"

write("1_sample", SAMPLE)
write("2_edges", [
    (100, 100, 3, 100, 100, 10),
    (0, 0, 1, 10000, 10000, 1),
    (100, 100, 7, 100, 100, 7),
    (100, 100, 1, 101, 100, 2),
    (101, 100, 2, 100, 100, 1),
    (100, 100, 10, 108, 106, 2),
])
tangent = []
for step in range(1, 200):
    small_radius = 5
    large_radius = small_radius + 5 * step
    tangent.append((10000, 0, small_radius,
                    10000 - 3 * step, 4 * step, large_radius))
write("3_wide", tangent)
random.seed(2026)
rnd = []
for _ in range(999):
    first_x, first_y = random.randint(0, 10000), random.randint(0, 10000)
    second_x, second_y = random.randint(0, 10000), random.randint(0, 10000)
    first_r, second_r = random.randint(1, 10000), random.randint(1, 10000)
    rnd.append((first_x, first_y, first_r, second_x, second_y, second_r))
write("4_random", rnd)
write("5_io", [(random.randint(0, 10000), random.randint(0, 10000),
                random.randint(1, 10000), random.randint(0, 10000),
                random.randint(0, 10000), random.randint(1, 10000))
               for _ in range(999)])
