#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor + 4 <= len(tokens):
        city_count = tokens[cursor]
        road_count = tokens[cursor + 1]
        group_x_count = tokens[cursor + 2]
        group_y_count = tokens[cursor + 3]
        cursor += 4
        if city_count == 0 and road_count == 0:
            break
        group_x = tokens[cursor:cursor + group_x_count]
        cursor += group_x_count
        group_y = tokens[cursor:cursor + group_y_count]
        cursor += group_y_count
        matrix = [[10 ** 18] * city_count for _ in range(city_count)]
        for city in range(city_count):
            matrix[city][city] = 0
        for _ in range(road_count):
            first = tokens[cursor]
            second = tokens[cursor + 1]
            length = tokens[cursor + 2]
            cursor += 3
            if length < matrix[first][second]:
                matrix[first][second] = length
                matrix[second][first] = length
        for via in range(city_count):
            for first in range(city_count):
                for second in range(city_count):
                    candidate = matrix[first][via] + matrix[via][second]
                    if candidate < matrix[first][second]:
                        matrix[first][second] = candidate
        best = min(matrix[x][y] for x in group_x for y in group_y)
        answers.append(str(best))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """4 4 2 2
0 1
2 3
0 1 10
0 2 20
1 3 10
2 3 100
0 0 0 0
"""
SAMPLE_OUT = """10
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1 1 1\n0\n1\n0 1 7\n0 0 0 0\n") == "7\n"
assert oracle("3 2 1 1\n0\n2\n0 1 4\n1 2 5\n0 0 0 0\n") == "9\n"
assert oracle("4 5 2 2\n0 1\n2 3\n0 1 2\n0 1 3\n2 3 6\n1 2 1\n3 0 20\n0 0 0 0\n") == "1\n"
assert oracle("0 0 0 0\n") == ""


def write(name, cases):
    text = "".join(case_text for case_text in cases) + "0 0 0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def case(city_count, group_x, group_y, roads):
    lines = [f"{city_count} {len(roads)} {len(group_x)} {len(group_y)}"]
    lines.append(" ".join(str(city) for city in group_x))
    lines.append(" ".join(str(city) for city in group_y))
    for first, second, length in roads:
        lines.append(f"{first} {second} {length}")
    return "\n".join(lines) + "\n"


def build():
    write("2_edges", [case(2, [0], [1], [(0, 1, 1)])])
    write("3_wide", [case(8, [0, 1], [6, 7], [
        (0, 1, 3), (0, 1, 12), (1, 2, 5), (2, 3, 7), (3, 4, 2),
        (4, 5, 9), (5, 6, 4), (6, 7, 8), (1, 6, 100), (0, 7, 90),
        (2, 4, 30), (3, 5, 25),
    ])])
    rng = random.Random(20261126)
    random_roads = [(city, city + 1, rng.randint(1, 10000)) for city in range(19)]
    random_roads += [
        (rng.randrange(20), rng.randrange(20), rng.randint(1, 10000))
        for _ in range(25)
    ]
    write("4_random", [case(20, [0, 3, 7], [12, 15, 19], random_roads)])
    many_cases = []
    for _ in range(200):
        many_cases.append(case(4, [0, 1], [2, 3], [
            (0, 1, rng.randint(1, 100)), (1, 2, rng.randint(1, 100)),
            (0, 2, rng.randint(1, 100)), (2, 3, rng.randint(1, 100)),
        ]))
    write("5_io", many_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
