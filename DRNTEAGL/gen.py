#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    lines = []
    for case_index, points in enumerate(cases, 1):
        distances = [math.hypot(x, y) for x, y in points]
        best_index = max(range(len(points)), key=lambda idx: distances[idx]) + 1
        lines.append(f"Case {case_index}: {best_index}")
    return "\n".join(lines) + "\n"


SAMPLE = [[(4, 0), (0, 5), (2, 2)], [(2, 3), (1, 1), (5, 5), (-4, -1)]]
SAMPLE_OUT = "Case 1: 2\nCase 2: 3\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle([[(0, 0)]]) == "Case 1: 1\n"
assert oracle([[(3, 4), (-3, -4)]]) == "Case 1: 1\n"
assert oracle([[(0, 0), (10000, 10000)]]) == "Case 1: 2\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n"
    for points in cases:
        input_text += str(len(points)) + "\n"
        input_text += "".join(f"{x} {y}\n" for x, y in points)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


write("1_sample", SAMPLE)
write("2_edges", [[(0, 0)], [(0, 0), (0, 0)], [(-10000, -10000), (10000, 10000)],
                  [(1, 0), (0, 1), (-1, 0), (0, -1)]])
write("3_wide", [[(random.randint(-10000, 10000), random.randint(-10000, 10000))
                  for _ in range(50)] for _ in range(100)])

random.seed(2026)
write("4_random", [[(random.randint(-10000, 10000), random.randint(-10000, 10000))
                    for _ in range(random.randint(1, 50))] for _ in range(100)])

write("5_io", [[(10000, 10000)] * 50 for _ in range(100)])
