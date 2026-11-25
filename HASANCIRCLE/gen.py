#!/usr/bin/env python3
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "1 1 2\n3 8 25\n"
SAMPLE_OUT = "1.047\n101.790\n"


def oracle(text):
    values = [int(token) for token in text.split()]
    values += [0] * ((-len(values)) % 3)
    answers = []
    for case_start in range(0, len(values), 3):
        point_y = values[case_start + 1]
        radius = values[case_start + 2]
        if radius == 0:
            answers.append("0.000")
            continue
        horizontal = math.sqrt(radius * radius - point_y * point_y)
        angle = math.atan2(point_y, horizontal)
        area = 0.5 * radius * radius * angle
        answers.append(f"{area:.3f}")
    return "".join(answer + "\n" for answer in answers)


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5 5 5\n") == "19.635\n"
assert oracle("0 0 5\n") == "0.000\n"
assert oracle("7 4 5\n") == "11.591\n"
assert oracle("1 1 1\n") == "0.785\n"


def write(name, cases):
    input_text = "".join(f"{point_x} {point_y} {radius}\n"
                         for point_x, point_y, radius in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def rounding_agrees(point_y, radius):
    horizontal = math.sqrt(max(0, radius * radius - point_y * point_y))
    atan_area = 0.5 * radius * radius * math.atan2(point_y, horizontal)
    asin_area = 0.5 * radius * radius * math.asin(point_y / radius)
    return f"{atan_area:.3f}" == f"{asin_area:.3f}"


def stable_cases(candidates, needed):
    chosen = []
    for point_x, point_y, radius in candidates:
        if rounding_agrees(point_y, radius):
            chosen.append((point_x, point_y, radius))
            if len(chosen) == needed:
                break
    return chosen


def build():
    write("2_edges", [(0, 0, 5), (1, 1, 1), (3, 0, 10),
                      (7, 4, 5), (9, 5, 5), (2, 3, 10)])
    write("3_wide", [(0, 10**9, 10**9), (10**9 - 1, 10**9 // 2, 10**9),
                     (1, 1, 10**7), (5, 10**7, 10**7)] * 5)
    rng = random.Random(20261125)
    random_candidates = []
    for _ in range(400):
        radius = rng.randint(1, 10**6)
        random_candidates.append((rng.randint(0, radius), rng.randint(0, radius), radius))
    write("4_random", stable_cases(random_candidates, 300))
    io_candidates = []
    for _ in range(25000):
        radius = rng.randint(1, 10**4)
        io_candidates.append((rng.randint(0, radius), rng.randint(0, radius), radius))
    write("5_io", stable_cases(io_candidates, 20000))


def worked_example():
    point_x, point_y, radius = 1, 1, 2
    horizontal = math.sqrt(radius * radius - point_y * point_y)
    angle_radians = math.atan2(point_y, horizontal)
    area = 0.5 * radius * radius * angle_radians
    print(f"C: ({point_x}, {point_y}), radius: {radius}")
    print(f"B horizontal offset: {horizontal:.6f}")
    print(f"angle radians: {angle_radians:.6f}")
    print(f"area rounded: {area:.3f}")


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(1, 1, 2), (3, 8, 25)])
    build()
    if "--trace" in sys.argv:
        worked_example()


if __name__ == "__main__":
    main()
