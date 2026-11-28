#!/usr/bin/env python3
import itertools
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def segments_cross(first_start, first_end, second_start, second_end):
    first_vector = (first_end[0] - first_start[0], first_end[1] - first_start[1])
    second_vector = (second_end[0] - second_start[0], second_end[1] - second_start[1])
    offset = (second_start[0] - first_start[0], second_start[1] - first_start[1])
    determinant = first_vector[0] * second_vector[1] - first_vector[1] * second_vector[0]
    if abs(determinant) < 1e-12:
        if abs(offset[0] * first_vector[1] - offset[1] * first_vector[0]) > 1e-9:
            return False
        length_squared = first_vector[0] ** 2 + first_vector[1] ** 2
        if length_squared == 0:
            return False
        first_parameter = (offset[0] * first_vector[0] + offset[1] * first_vector[1]) / length_squared
        far_offset = (second_end[0] - first_start[0], second_end[1] - first_start[1])
        second_parameter = (far_offset[0] * first_vector[0] +
                            far_offset[1] * first_vector[1]) / length_squared
        lower = max(0.0, min(first_parameter, second_parameter))
        upper = min(1.0, max(first_parameter, second_parameter))
        return lower <= upper
    along = (offset[0] * second_vector[1] - offset[1] * second_vector[0]) / determinant
    across = (offset[0] * first_vector[1] - offset[1] * first_vector[0]) / determinant
    return -1e-9 <= along <= 1 + 1e-9 and -1e-9 <= across <= 1 + 1e-9


def distance(first, second):
    return math.hypot(first[0] - second[0], first[1] - second[1])


def oracle_case(leaves, sticks, jump_limit):
    points = [(0, 0)] + leaves
    best_distance = None
    best_path = None
    for order in itertools.permutations(range(1, len(points))):
        used_jumps = 0
        total_distance = 0.0
        previous = 0
        for leaf in order:
            for stick_start, stick_end in sticks:
                if segments_cross(points[previous], points[leaf], stick_start, stick_end):
                    used_jumps += 1
            if used_jumps > jump_limit:
                break
            total_distance += distance(points[previous], points[leaf])
            previous = leaf
        if used_jumps > jump_limit:
            continue
        if best_distance is None or total_distance < best_distance - 1e-9:
            best_distance = total_distance
            best_path = order
        elif abs(total_distance - best_distance) < 1e-9 and order < best_path:
            best_path = order
    if best_distance is None:
        return "-1", None
    return f"{best_distance:.3f}", best_path


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    lines = []
    for case_number in range(1, case_count + 1):
        leaf_count = int(tokens[cursor])
        stick_count = int(tokens[cursor + 1])
        jump_limit = int(tokens[cursor + 2])
        cursor += 3
        leaves = []
        for _ in range(leaf_count):
            leaves.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        sticks = []
        for _ in range(stick_count):
            sticks.append(((int(tokens[cursor]), int(tokens[cursor + 1])),
                           (int(tokens[cursor + 2]), int(tokens[cursor + 3]))))
            cursor += 4
        result, path = oracle_case(leaves, sticks, jump_limit)
        lines.append(f"Scenario #{case_number}: {result}")
        if path is not None:
            lines.append(" ".join(str(index) for index in (0,) + path))
    return "\n".join(lines) + "\n"


SAMPLE = """2
6 3 1
1 6
2 2
5 1
5 5
5 9
10 2
2 5 4 3
3 7 8 7
6 0 8 3
4 3 2
-2 -2
2 2
5 -1
6 6
0 3 1 0
-2 -5 5 2
0 5 7 0
"""
SAMPLE_OUT = """Scenario #1: 26.044
0 2 3 6 4 1 5
Scenario #2: -1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 0 1\n3 4\n") == "Scenario #1: 5.000\n0 1\n"
assert oracle("1\n2 0 0\n1 0\n0 1\n") == "Scenario #1: 2.414\n0 1 2\n"
assert oracle("1\n1 1 0\n3 4\n0 0 6 8\n") == "Scenario #1: -1\n"
assert abs(distance((0, 0), (3, 4)) - 5.0) < 1e-12


def case_text(leaves, sticks, jump_limit):
    text = f"{len(leaves)} {len(sticks)} {jump_limit}\n"
    for point_x, point_y in leaves:
        text += f"{point_x} {point_y}\n"
    for start, end in sticks:
        text += f"{start[0]} {start[1]} {end[0]} {end[1]}\n"
    return text


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, leaf_count, stick_count, jump_limit):
    leaves = [(rng.randint(-100, 100), rng.randint(-100, 100))
              for _ in range(leaf_count)]
    sticks = [((rng.randint(-100, 100), rng.randint(-100, 100)),
               (rng.randint(-100, 100), rng.randint(-100, 100)))
              for _ in range(stick_count)]
    return leaves, sticks, jump_limit


def build():
    write("2_edges", [([(3, 4)], [], 1),
                      ([(1, 0), (0, 1)], [], 0),
                      ([(3, 4)], [((0, 0), (6, 8))], 0)])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 6, 10, 2) for _ in range(3)])
    write("4_random", [random_case(rng, rng.randint(1, 5), rng.randint(0, 6),
                                   rng.randint(0, 2)) for _ in range(10)])
    write("5_io", [random_case(rng, 6, 10, 3) for _ in range(10)])
    big_rng = random.Random(4302)
    with open("/tmp/VPL1_AD_big.txt", "w") as handle:
        handle.write("10\n")
        for _ in range(10):
            handle.write(case_text(*random_case(big_rng, 10, 10, 5)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([(1, 6), (2, 2), (5, 1), (5, 5), (5, 9), (10, 2)],
                    [((2, 5), (4, 3)), ((3, 7), (8, 7)), ((6, 0), (8, 3))], 1),
                   ([( -2, -2), (2, 2), (5, -1), (6, 6)],
                    [((0, 3), (1, 0)), ((-2, -5), (5, 2)), ((0, 5), (7, 0))], 2)])
build()
