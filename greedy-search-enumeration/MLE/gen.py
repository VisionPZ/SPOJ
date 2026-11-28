#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        count = int(tokens[cursor]); cursor += 1
        points = []
        for _ in range(count):
            x = int(tokens[cursor]); cursor += 1
            y = int(tokens[cursor]); cursor += 1
            points.append((x, y))
        for index, (x_value, y_value) in enumerate(points):
            closest = None
            for other_index, (other_x, other_y) in enumerate(points):
                if other_index == index:
                    continue
                distance = ((x_value - other_x) ** 2 +
                            (y_value - other_y) ** 2)
                if closest is None or distance < closest:
                    closest = distance
            answers.append(str(closest))
    return "\n".join(answers) + "\n"


SAMPLE = """2
10
17 41
0 34
24 19
8 28
14 12
45 5
27 31
41 11
42 45
36 27
15
0 0
1 2
2 3
3 2
4 0
8 4
7 4
6 3
6 1
8 0
11 0
12 2
13 1
14 2
15 0
"""
SAMPLE_OUT = """200
100
149
100
149
52
97
52
360
97
5
2
2
2
5
1
1
2
4
5
5
2
2
2
5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n0 0\n3 4\n0\n") == "25\n25\n"
assert oracle("1\n3\n0 0\n1 0\n3 0\n") == "1\n1\n4\n"
assert oracle("1\n4\n0 0\n0 1\n0 3\n0 6\n") == "1\n1\n4\n9\n"


def write(name, cases):
    chunks = [str(len(cases)) + "\n"]
    for points in cases:
        chunks.append(str(len(points)) + "\n")
        chunks.append("".join(f"{x} {y}\n" for x, y in points))
    input_text = "".join(chunks)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [
        [(0, 0), (0, 1), (0, 3), (0, 6)],
        [(0, 0), (5, 0), (10, 0), (20, 0), (40, 0)],
        [(-7, -9), (8, 12), (100, 100)],
    ])
    rng = random.Random(20261126)
    wide = [(rng.randint(-10000, 10000), rng.randint(-10000, 10000))
            for _ in range(200)]
    write("3_wide", [wide])
    random_cases = []
    for _ in range(2):
        random_cases.append([(rng.randint(-5000, 5000), rng.randint(-5000, 5000))
                             for _ in range(150)])
    write("4_random", random_cases)
    io_points = [(rng.randint(-10000, 10000), rng.randint(-10000, 10000))
                 for _ in range(300)]
    write("5_io", [io_points])
    big_points = [(rng.randint(-10 ** 9, 10 ** 9), rng.randint(-10 ** 9, 10 ** 9))
                  for _ in range(100000)]
    Path("/tmp/MLE_big.txt").write_text(
        "1\n" + str(len(big_points)) + "\n" +
        "".join(f"{x} {y}\n" for x, y in big_points))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
