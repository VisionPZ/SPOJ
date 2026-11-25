#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def best_line(points):
    best = 0
    for combo in itertools.combinations(points, 4):
        first_x, first_y = combo[0]
        delta_x = combo[1][0] - first_x
        delta_y = combo[1][1] - first_y
        if delta_x == 0 and delta_y == 0:
            continue
        if all((x - first_x) * delta_y == (y - first_y) * delta_x for x, y in combo[2:]):
            count = sum(1 for x, y in points if (x - first_x) * delta_y == (y - first_y) * delta_x)
            best = max(best, count)
    return best if best >= 4 else 0


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    answers = []
    while position < len(tokens):
        count = tokens[position]
        position += 1
        if count == 0:
            break
        points = []
        for _ in range(count):
            points.append((tokens[position], tokens[position + 1]))
            position += 2
        answers.append(f"Photo {len(answers) + 1}: {best_line(points)} points eliminated")
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """6
0 1
0 2
1 2
2 2
4 5
5 6
4
3 5
4 4
6 5
7 4
0
"""
SAMPLE_OUT = """Photo 1: 4 points eliminated
Photo 2: 0 points eliminated
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert best_line([(i, 2 * i + 1) for i in range(5)]) == 5
assert best_line([(0, 0), (1, 0), (2, 0), (3, 1)]) == 0
assert best_line([(0, 0), (1, 1), (2, 4), (3, 9)]) == 0
assert best_line([(5, i) for i in range(6)]) == 6


def write_case(name, photos):
    chunks = []
    for points in photos:
        chunks.append(str(len(points)) + "\n")
        chunks.extend(f"{x} {y}\n" for x, y in points)
    text = "".join(chunks) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        [(0, 0), (1, 0), (2, 0), (3, 0)],
        [(0, 0), (1, 0), (2, 0), (3, 1)],
        [(i, i) for i in range(8)],
        [(0, i) for i in range(7)],
    ])
    rng = random.Random(20261126)
    wide = [(i, 3 * i + 2) for i in range(18)]
    wide += [(rng.randint(0, 10000), rng.randint(0, 10000)) for _ in range(7)]
    rng.shuffle(wide)
    write_case("3_wide", [wide, [(i, 10000 - 2 * i) for i in range(12)]])
    photos = []
    for _ in range(20):
        size = rng.randint(4, 12)
        photos.append([(rng.randint(0, 60), rng.randint(0, 60)) for _ in range(size)])
    write_case("4_random", photos)
    rng = random.Random(991233)
    photos = []
    for _ in range(400):
        size = rng.randint(4, 9)
        photos.append([(rng.randint(0, 40), rng.randint(0, 40)) for _ in range(size)])
    write_case("5_io", photos)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
