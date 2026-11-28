#!/usr/bin/env python3
import math
import random
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
DIRECTIONS = [(1, 0, "E"), (0, 1, "N"), (1, 1, "NE"), (-1, 1, "NW"),
              (0, -1, "S"), (1, -1, "SE"), (-1, -1, "SW"), (-1, 0, "W")]


def length(index):
    return math.sqrt(2.0) if DIRECTIONS[index][0] and DIRECTIONS[index][1] else 1.0


def oracle_case(start_x, start_y, target_x, target_y):
    delta_x = target_x - start_x
    delta_y = target_y - start_y
    choices = []
    for index, (unit_x, unit_y, _) in enumerate(DIRECTIONS):
        if delta_x * unit_y - delta_y * unit_x == 0 and delta_x * unit_x + delta_y * unit_y > 0:
            steps = delta_x / unit_x if unit_x else delta_y / unit_y
            choices.append((steps * length(index), index, -1, start_x, start_y))
    if not choices:
        for first, (unit_x, unit_y, _) in enumerate(DIRECTIONS):
            for second, (other_x, other_y, _) in enumerate(DIRECTIONS):
                if first == second:
                    continue
                matrix = np.array([[unit_x, other_x], [unit_y, other_y]], dtype=float)
                if abs(np.linalg.det(matrix)) < 1e-12:
                    continue
                steps = np.linalg.solve(matrix, np.array([delta_x, delta_y], dtype=float))
                if steps[0] <= 1e-9 or steps[1] <= 1e-9:
                    continue
                cost = steps[0] * length(first) + steps[1] * length(second)
                split_x = start_x + steps[0] * unit_x
                split_y = start_y + steps[0] * unit_y
                choices.append((cost, first, second, split_x, split_y))
    best = min(choices, key=lambda item: (round(item[0], 7), item[1], item[2]))
    lines = [str(2 if best[2] < 0 else 3)]
    lines.append(f"{float(start_x):.2f} {float(start_y):.2f} {DIRECTIONS[best[1]][2]}")
    if best[2] >= 0:
        lines.append(f"{best[3]:.2f} {best[4]:.2f} {DIRECTIONS[best[2]][2]}")
    lines.append(f"{float(target_x):.2f} {float(target_y):.2f} X")
    lines.append(f"{best[0]:.3f}")
    return "\n".join(lines) + "\n\n"


def brute_cost(start_x, start_y, target_x, target_y):
    best = math.inf
    low_x = min(start_x, target_x) * 2 - 2
    high_x = max(start_x, target_x) * 2 + 2
    low_y = min(start_y, target_y) * 2 - 2
    high_y = max(start_y, target_y) * 2 + 2
    for half_x in range(low_x, high_x + 1):
        for half_y in range(low_y, high_y + 1):
            split_x = half_x / 2.0
            split_y = half_y / 2.0
            for first, (unit_x, unit_y, _) in enumerate(DIRECTIONS):
                off_x = split_x - start_x
                off_y = split_y - start_y
                if abs(off_x * unit_y - off_y * unit_x) > 1e-9:
                    continue
                first_steps = (off_x * unit_x + off_y * unit_y) / (unit_x * unit_x + unit_y * unit_y)
                if first_steps <= 1e-9:
                    continue
                for second, (other_x, other_y, _) in enumerate(DIRECTIONS):
                    if first == second:
                        continue
                    rest_x = target_x - split_x
                    rest_y = target_y - split_y
                    if abs(rest_x * other_y - rest_y * other_x) > 1e-9:
                        continue
                    second_steps = (rest_x * other_x + rest_y * other_y) / (other_x * other_x + other_y * other_y)
                    if second_steps <= 1e-9:
                        continue
                    cost = first_steps * length(first) + second_steps * length(second)
                    best = min(best, cost)
    return best


SAMPLE = """0 0 0 1
0 0 3 2
"""
SAMPLE_OUT = """2
0.00 0.00 N
0.00 1.00 X
1.000

3
0.00 0.00 E
1.00 0.00 NE
3.00 2.00 X
3.828

"""
assert oracle_case(0, 0, 0, 1) == SAMPLE_OUT.split("\n\n")[0] + "\n\n"
assert oracle_case(0, 0, 3, 2) == SAMPLE_OUT.split("\n\n")[1] + "\n\n"
assert oracle_case(0, 0, 5, 0) == "2\n0.00 0.00 E\n5.00 0.00 X\n5.000\n\n"
assert oracle_case(1, 1, 4, 3) == "3\n1.00 1.00 E\n2.00 1.00 NE\n4.00 3.00 X\n3.828\n\n"
for case in [(0, 0, 3, 2), (0, 0, 5, 1), (1, 2, -3, 4), (-2, -1, 3, -4)]:
    result = oracle_case(*case)
    cost = float(result.split("\n")[-3])
    assert abs(cost - round(brute_cost(*case), 3)) < 1e-9


def oracle(text):
    tokens = [int(value) for value in text.split()]
    return "".join(oracle_case(*tokens[index:index + 4]) for index in range(0, len(tokens), 4))


def write(name, cases):
    text = "".join(f"{one[0]} {one[1]} {one[2]} {one[3]}\n" for one in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0, 1, 1), (0, 0, -5, 0), (3, -2, 3, 7), (-4, -4, 4, -4)])
    write("3_wide", [(-50000, -50000, 50000, 49999), (50000, -50000, -49999, 50000)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(-50000, 50000), rng.randint(-50000, 50000),
                        rng.randint(-50000, 50000), rng.randint(-50000, 50000)) for _ in range(100)])
    write("5_io", [(rng.randint(-50000, 50000), rng.randint(-50000, 50000),
                    rng.randint(-50000, 50000), rng.randint(-50000, 50000)) for _ in range(2000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(0, 0, 0, 1), (0, 0, 3, 2)])
build()
