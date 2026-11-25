#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def rotate_point(point, turns):
    x, y = point
    for _ in range(turns):
        x, y = -y, x
    return x, y


def normalized(points):
    points = list(points)
    variants = []
    for order in (points, points[::-1]):
        for turns in range(4):
            turned = [rotate_point(point, turns) for point in order]
            base_x, base_y = turned[0]
            variants.append(tuple((x - base_x, y - base_y) for x, y in turned))
    return min(variants)


def oracle(text):
    tokens = text.split()
    position = 0
    lines = []
    while position < len(tokens):
        line_count = int(tokens[position])
        position += 1
        if line_count == 0:
            break
        vertex_count = int(tokens[position])
        position += 1
        template = []
        for _ in range(vertex_count):
            template.append((int(tokens[position]), int(tokens[position + 1])))
            position += 2
        target = normalized(template)
        for line_index in range(1, line_count + 1):
            count = int(tokens[position])
            position += 1
            candidate = []
            for _ in range(count):
                candidate.append((int(tokens[position]), int(tokens[position + 1])))
                position += 2
            if normalized(candidate) == target:
                lines.append(str(line_index))
        lines.append("+++++")
    return "\n".join(lines) + "\n"


SAMPLE = """5
5
0 0
2 0
2 1
4 1
4 0
5
0 0
0 2
-1 2
-1 4
0 4
5
0 0
0 1
-2 1
-2 2
0 2
5
0 0
0 -1
2 -1
2 0
4 0
5
0 0
2 0
2 -1
4 -1
4 0
5
0 0
2 0
2 1
4 1
4 0
4
4
-60 -75
-60 -78
-42 -78
-42 -6
4
10 3
10 7
-4 7
-4 40
4
-74 66
-74 63
-92 63
-92 135
4
-12 22
-12 25
-30 25
-30 -47
4
12 -22
12 -25
30 -25
30 47
3
5
-8 5
-8 2
0 2
0 4
8 4
5
-3 -1
0 -1
0 7
-2 7
-2 16
5
-1 6
-1 3
7 3
7 5
16 5
5
0 1
0 -2
8 -2
8 0
17 0
0
"""
SAMPLE_OUT = """1
3
5
+++++
3
4
+++++
+++++
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3\n0 0\n2 0\n2 1\n3\n5 5\n7 5\n7 6\n0\n") == "1\n+++++\n"
assert oracle("1\n3\n0 0\n2 0\n2 1\n3\n0 0\n0 2\n2 2\n0\n") == "+++++\n"
assert oracle("1\n3\n0 0\n2 0\n2 1\n3\n2 1\n2 0\n0 0\n0\n") == "1\n+++++\n"
assert normalized([(0, 0), (2, 0), (2, 1)]) == normalized([(0, 0), (0, -2), (1, -2)])


def line_text(points):
    return str(len(points)) + "\n" + "".join(f"{x} {y}\n" for x, y in points)


def dataset(template, candidates):
    return str(len(candidates)) + "\n" + line_text(template) + "".join(
        line_text(points) for points in candidates
    )


def transform(points, turns, flip, shift_x, shift_y):
    work = [(x, -y) if flip else (x, y) for x, y in points]
    work = [rotate_point(point, turns) for point in work]
    return [(x + shift_x, y + shift_y) for x, y in work]


def random_line(rng, vertex_count):
    directions = [(1, 0), (0, 1), (-1, 0), (0, -1)]
    for _ in range(200):
        heading = rng.randrange(4)
        points = [(rng.randint(-50, 50), rng.randint(-50, 50))]
        for _ in range(vertex_count - 1):
            heading = (heading + rng.choice((1, 3))) % 4
            step = rng.randint(1, 6)
            last_x, last_y = points[-1]
            delta_x, delta_y = directions[heading]
            points.append((last_x + step * delta_x, last_y + step * delta_y))
        if len(set(points)) == vertex_count:
            return points
    return [(0, 0), (1, 0), (1, 1), (2, 1)]


def write(name, datasets):
    text = "".join(datasets) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    template = [(0, 0), (3, 0), (3, 2), (5, 2)]
    edges = [
        template,
        transform(template, 1, False, 10, 20),
        transform(template[::-1], 2, False, -7, 4),
        transform(template, 0, True, 0, 0),
    ]
    write("2_edges", [dataset(template, edges)])
    rng = random.Random(20261126)
    wide_template = random_line(rng, 10)
    wide_candidates = []
    for _ in range(50):
        if rng.random() < 0.5:
            wide_candidates.append(transform(wide_template, rng.randrange(4), False,
                                             rng.randint(-100, 100), rng.randint(-100, 100)))
        else:
            wide_candidates.append(random_line(rng, 10))
    write("3_wide", [dataset(wide_template, wide_candidates)])
    mixed = []
    for _ in range(30):
        shape = random_line(rng, rng.randint(3, 10))
        candidates = []
        for _ in range(rng.randint(1, 50)):
            if rng.random() < 0.4:
                candidates.append(transform(shape, rng.randrange(4), False,
                                            rng.randint(-1000, 1000), rng.randint(-1000, 1000)))
            else:
                candidates.append(random_line(rng, rng.randint(3, 10)))
        mixed.append(dataset(shape, candidates))
    write("4_random", mixed)
    io_template = random_line(rng, 10)
    matching = [transform(io_template, index % 4, False, index, -index)
                for index in range(50)]
    write("5_io", [dataset(io_template, matching) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
