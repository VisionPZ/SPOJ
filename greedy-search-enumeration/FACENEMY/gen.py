#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    position = 1
    results = []
    for _ in range(case_count):
        values = [int(token) for token in tokens[position:position + 8]]
        position += 8
        hero_x, hero_y, hero_face_x, hero_face_y = values[:4]
        heroine_x, heroine_y, heroine_face_x, heroine_face_y = values[4:]
        hero_turn = abs(math.atan2(
            (hero_face_x - hero_x) * (heroine_y - hero_y)
            - (hero_face_y - hero_y) * (heroine_x - hero_x),
            (hero_face_x - hero_x) * (heroine_x - hero_x)
            + (hero_face_y - hero_y) * (heroine_y - hero_y)))
        heroine_turn = abs(math.atan2(
            (heroine_face_x - heroine_x) * (hero_y - heroine_y)
            - (heroine_face_y - heroine_y) * (hero_x - heroine_x),
            (heroine_face_x - heroine_x) * (hero_x - heroine_x)
            + (heroine_face_y - heroine_y) * (hero_y - heroine_y)))
        if hero_turn + 1e-9 < heroine_turn:
            results.append("Hero")
        elif heroine_turn + 1e-9 < hero_turn:
            results.append("Heroine")
        else:
            results.append("0")
    return "\n".join(results) + "\n"


SAMPLE = """10
9 3 6 0 4 4 6 6
1 8 6 3 4 9 7 8
8 2 3 5 9 1 9 8
4 0 3 6 7 6 1 5
4 2 7 3 0 9 7 2
6 0 5 7 1 6 5 4
1 2 1 4 0 0 6 0
7 1 7 7 7 7 3 3
5 9 1 8 9 8 2 6
6 0 0 1 3 8 2 5
"""
SAMPLE_OUT = """0
Hero
Heroine
Hero
Heroine
Heroine
Heroine
Hero
Heroine
Heroine
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0 0 1 0 0 1 0 2\n") == "Hero\n"
assert oracle("1\n5 5 4 5 6 5 7 5\n") == "0\n"
assert oracle("1\n0 0 1 0 1 0 0 1\n") == "Hero\n"
assert oracle("1\n0 0 0 1 1 0 2 0\n") == "Hero\n"


def write(name, cases):
    text = str(len(cases)) + "\n"
    text += "".join(" ".join(str(value) for value in case) + "\n" for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng):
    hero_x, hero_y = rng.randint(0, 100), rng.randint(0, 100)
    hero_face_x, hero_face_y = hero_x, hero_y
    while (hero_face_x, hero_face_y) == (hero_x, hero_y):
        hero_face_x, hero_face_y = rng.randint(0, 100), rng.randint(0, 100)
    heroine_x, heroine_y = hero_x, hero_y
    while (heroine_x, heroine_y) == (hero_x, hero_y):
        heroine_x, heroine_y = rng.randint(0, 100), rng.randint(0, 100)
    heroine_face_x, heroine_face_y = heroine_x, heroine_y
    while (heroine_face_x, heroine_face_y) == (heroine_x, heroine_y):
        heroine_face_x, heroine_face_y = rng.randint(0, 100), rng.randint(0, 100)
    return (hero_x, hero_y, hero_face_x, hero_face_y,
            heroine_x, heroine_y, heroine_face_x, heroine_face_y)


def build():
    write("2_edges", [
        (0, 0, 1, 0, 0, 1, 0, 2),
        (5, 5, 4, 5, 6, 5, 7, 5),
        (0, 0, 1, 0, 1, 0, 0, 1),
        (0, 0, 0, 1, 1, 0, 1, 1),
        (5, 5, 5, 6, 6, 5, 4, 5),
        (0, 0, 100, 100, 100, 0, 0, 100),
    ])
    write("3_wide", [
        (0, 0, 100, 0, 100, 100, 100, 0),
        (100, 100, 0, 100, 0, 0, 0, 100),
        (0, 100, 0, 0, 100, 0, 100, 100),
        (100, 0, 0, 0, 0, 100, 0, 0),
    ])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng) for _ in range(1000)])
    write("5_io", [random_case(rng) for _ in range(200000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
