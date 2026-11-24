#!/usr/bin/env python3
import random
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
MAX_EDGE = 10**6


def best_for_x(sorted_by_y, y_values, edge_x):
    active = sorted_by_y[sorted_by_y[:, 0] < edge_x]
    min_z = np.full(y_values.shape, MAX_EDGE, dtype=np.int64)
    if active.shape[0] > 0:
        prefix_min = np.minimum.accumulate(active[:, 2])
        place = np.searchsorted(active[:, 1], y_values, side="left") - 1
        valid = place >= 0
        min_z[valid] = prefix_min[place[valid]]
    products = y_values * min_z
    top = int(products.max())
    winning = np.flatnonzero(products == top)
    return edge_x * top, (edge_x, int(y_values[winning[-1]]), int(min_z[winning[-1]]))


def oracle_case(points):
    if not points:
        return (MAX_EDGE, MAX_EDGE, MAX_EDGE)
    data = np.array(points, dtype=np.int64)
    sorted_by_y = data[np.argsort(data[:, 1], kind="stable")]
    x_values = np.unique(np.append(data[:, 0], MAX_EDGE))
    y_values = np.unique(np.append(data[:, 1], MAX_EDGE))
    best_volume = -1
    answer = None
    for edge_x in x_values:
        volume, candidate = best_for_x(sorted_by_y, y_values, int(edge_x))
        if volume > best_volume:
            best_volume = volume
            answer = candidate
    volume, candidate = best_for_x(sorted_by_y, y_values, MAX_EDGE)
    if volume > best_volume:
        answer = candidate
    return answer


def brute_case(points):
    x_values = sorted({p[0] for p in points} | {MAX_EDGE})
    y_values = sorted({p[1] for p in points} | {MAX_EDGE})
    z_values = sorted({p[2] for p in points} | {MAX_EDGE})
    best = -1
    answer = None
    for edge_x in x_values:
        for edge_y in y_values:
            for edge_z in z_values:
                if any(p[0] < edge_x and p[1] < edge_y and p[2] < edge_z
                       for p in points):
                    continue
                volume = edge_x * edge_y * edge_z
                if volume > best:
                    best = volume
                    answer = (edge_x, edge_y, edge_z)
    return answer, best


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        point_count = int(tokens[cursor]); cursor += 1
        points = []
        for _ in range(point_count):
            points.append((int(tokens[cursor]), int(tokens[cursor + 1]),
                           int(tokens[cursor + 2])))
            cursor += 3
        edge_x, edge_y, edge_z = oracle_case(points)
        answers.append(f"{edge_x} {edge_y} {edge_z}")
    return "\n".join(answers) + "\n"


def write(name, cases):
    pieces = [str(len(cases)), "\n"]
    for case in cases:
        pieces.append(f"{len(case)}\n")
        for point in case:
            pieces.append(f"{point[0]} {point[1]} {point[2]}\n")
        pieces.append("\n")
    input_text = "".join(pieces)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_INPUT = ("1\n4\n3 3 300000\n2 200000 5\n"
                "90000 3 2000\n2 2 1000\n")
SAMPLE_OUTPUT = "1000000 200000 1000\n"

assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle_case([]) == (MAX_EDGE, MAX_EDGE, MAX_EDGE)
assert oracle_case([(5, 7, 9)]) == (MAX_EDGE, MAX_EDGE, 9)
assert oracle_case([(MAX_EDGE, 1, 1)]) == (MAX_EDGE, MAX_EDGE, MAX_EDGE)
check_rng = random.Random(1977)
for _ in range(300):
    sample_points = [(check_rng.randint(1, 6), check_rng.randint(1, 6),
                      check_rng.choice([1, 2, 3, MAX_EDGE]))
                     for _ in range(check_rng.randint(0, 7))]
    _, brute_volume = brute_case(sample_points)
    oracle_edge_x, oracle_edge_y, oracle_edge_z = oracle_case(sample_points)
    assert oracle_edge_x * oracle_edge_y * oracle_edge_z == brute_volume


def build():
    edges = [
        [],
        [(1, 1, 1)],
        [(MAX_EDGE, MAX_EDGE, MAX_EDGE)],
        [(MAX_EDGE, 1, 1)],
        [(1, MAX_EDGE, 1), (MAX_EDGE, 1, MAX_EDGE)],
        [(5, 5, 5), (5, 5, 5), (5, 5, 5)],
        [(1, 1, 1), (1, 1, 2), (1, 2, 1), (2, 1, 1)],
        [(500000, 400000, 300000)],
        [(1, 1, MAX_EDGE), (1, MAX_EDGE, 1), (MAX_EDGE, 1, 1)],
        [(MAX_EDGE - 1, MAX_EDGE - 1, MAX_EDGE - 1), (1, 2, 3)],
    ]
    write("2_edges", edges)

    rng = random.Random(4242)
    wide_cases = []
    for _ in range(10):
        points = []
        for _ in range(2000):
            if rng.random() < 0.5:
                point = (rng.choice([1, 2, 3, MAX_EDGE - 2, MAX_EDGE - 1,
                                     MAX_EDGE]),
                         rng.choice([1, 2, 3, MAX_EDGE - 2, MAX_EDGE - 1,
                                     MAX_EDGE]),
                         rng.choice([1, 2, 3, MAX_EDGE - 2, MAX_EDGE - 1,
                                     MAX_EDGE]))
            else:
                point = (rng.randint(1, MAX_EDGE), rng.randint(1, MAX_EDGE),
                         rng.randint(1, MAX_EDGE))
            points.append(point)
        wide_cases.append(points)
    write("3_wide", wide_cases)

    rng = random.Random(2026)
    random_cases = [
        [(rng.randint(1, MAX_EDGE), rng.randint(1, MAX_EDGE),
          rng.randint(1, MAX_EDGE))
         for _ in range(rng.randint(1, 800))]
        for _ in range(10)
    ]
    write("4_random", random_cases)

    rng = random.Random(31415)
    io_cases = [
        [(rng.randint(1, MAX_EDGE), rng.randint(1, MAX_EDGE),
          rng.randint(1, MAX_EDGE))
         for _ in range(5000)]
        for _ in range(10)
    ]
    write("5_io", io_cases)


def worked_example():
    points = [(3, 3, 300000), (2, 200000, 5),
              (90000, 3, 2000), (2, 2, 1000)]
    data = np.array(points, dtype=np.int64)
    sorted_by_y = data[np.argsort(data[:, 1], kind="stable")]
    y_values = np.unique(np.append(data[:, 1], MAX_EDGE))
    for edge_x in sorted({p[0] for p in points} | {MAX_EDGE}):
        volume, (_, picked_y, picked_z) = best_for_x(sorted_by_y, y_values,
                                                     edge_x)
        print(f"X={edge_x} Y*Z={volume // edge_x} "
              f"Y={picked_y} Z={picked_z} volume={volume}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
worked_example()
