#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DIRECTIONS = 6


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        source_count = tokens[position]
        cube_side = tokens[position + 1]
        position += 2
        sources = []
        for _ in range(source_count):
            point = tuple(tokens[position:position + 3])
            position += 3
            distances = []
            for axis in range(3):
                distances.append(point[axis])
                distances.append(cube_side - point[axis])
            sources.append(distances)
        best_time = 0
        for choices in itertools.product(*sources):
            first_wall = min(choices)
            if first_wall > best_time:
                best_time = first_wall
        answers.append(str(best_time))
    return "\n".join(answers) + "\n"


SAMPLE = """2
1 10
5 5 5
2 10
1 1 1
1 1 2
"""
SAMPLE_OUT = """5
9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 10 5 5 5\n") == "5\n"
assert oracle("1 1 7 1 6 3\n") == "6\n"
assert oracle("1 2 20 1 1 1 19 19 19\n") == "19\n"


def formula(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        source_count = tokens[position]
        cube_side = tokens[position + 1]
        position += 2
        worst = cube_side
        for _ in range(source_count):
            point = tuple(tokens[position:position + 3])
            position += 3
            options = [max(coordinate, cube_side - coordinate) for coordinate in point]
            worst = min(worst, max(options))
        answers.append(str(worst))
    return "\n".join(answers) + "\n"


def make_cases(source_count, cube_side, rng):
    lines = []
    for _ in range(source_count):
        point = [rng.randint(1, cube_side - 1) for _ in range(3)]
        lines.append(f"{point[0]} {point[1]} {point[2]}")
    return lines


def write(name, cases):
    text = str(len(cases)) + "\n"
    for cube_side, points in cases:
        text += f"{len(points)} {cube_side}\n"
        text += "".join(point + "\n" for point in points)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    expected = oracle(text)
    assert expected == formula(text)
    (ROOT / "out" / f"{name}.out").write_text(expected)


def build():
    rng = random.Random(20261126)
    write("2_edges", [(10, ["1 1 1"]), (10, ["9 9 9"]), (5, ["2 3 2", "3 2 3"])])
    write("3_wide", [(1000, make_cases(5, 1000, rng)) for _ in range(20)])
    random_cases = []
    for _ in range(20):
        cube_side = rng.randint(50, 1000)
        random_cases.append((cube_side, make_cases(rng.randint(1, 5), cube_side, rng)))
    write("4_random", random_cases)
    write("5_io", [(1000, make_cases(5, 1000, rng)) for _ in range(50)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(10, ["5 5 5"]), (10, ["1 1 1", "1 1 2"])])
build()
