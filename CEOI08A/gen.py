#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

POST_COST = 20
TREE_LOSS = 111


def cross(origin, first, second):
    return (first[0] - origin[0]) * (second[1] - origin[1]) - (first[1] - origin[1]) * (second[0] - origin[0])


def convex_hull(points):
    ordered = sorted(set(points))
    if len(ordered) <= 2:
        return ordered
    lower = []
    for point in ordered:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper = []
    for point in reversed(ordered):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    return lower[:-1] + upper[:-1]


def trees_inside(hull, trees):
    total = 0
    for tree in trees:
        enclosed = True
        for index in range(len(hull)):
            if cross(hull[index], hull[(index + 1) % len(hull)], tree) < 0:
                enclosed = False
                break
        if enclosed:
            total += 1
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    hole_total = tokens[0]
    tree_total = tokens[1]
    holes = [(tokens[2 + 2 * index], tokens[3 + 2 * index]) for index in range(hole_total)]
    offset = 2 + 2 * hole_total
    trees = [(tokens[offset + 2 * index], tokens[offset + 2 * index + 1]) for index in range(tree_total)]
    best = TREE_LOSS * tree_total
    for size in range(3, hole_total + 1):
        for subset in itertools.combinations(holes, size):
            hull = convex_hull(subset)
            if len(hull) < 3:
                continue
            enclosed = trees_inside(hull, trees)
            cost = POST_COST * len(hull) + TREE_LOSS * (tree_total - enclosed)
            if cost < best:
                best = cost
    return str(best) + "\n"


SAMPLE = """4 3
800 300
200 200
200 700
600 700
400 300
600 500
800 900
"""
SAMPLE_OUT = """171
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 1\n0 0\n10 0\n0 10\n2 2\n") == "60\n"
assert oracle("3 1\n0 0\n10 0\n0 10\n20 20\n") == "111\n"
assert oracle("3 5\n0 0\n10 0\n0 10\n1 1\n2 2\n3 3\n4 4\n5 5\n") == "60\n"


def write(name, holes, trees):
    text = f"{len(holes)} {len(trees)}\n"
    text += "".join(f"{x_coord} {y_coord}\n" for x_coord, y_coord in holes)
    text += "".join(f"{x_coord} {y_coord}\n" for x_coord, y_coord in trees)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def distinct_points(rng, count):
    points = []
    while len(points) < count:
        point = (rng.randint(0, 1000), rng.randint(0, 1000))
        if point in points:
            continue
        if any(cross(points[a], points[b], point) == 0
               for a in range(len(points)) for b in range(a + 1, len(points))):
            continue
        points.append(point)
    return points


def distinct_trees(rng, count, holes):
    points = []
    while len(points) < count:
        point = (rng.randint(0, 1000), rng.randint(0, 1000))
        if point in points or point in holes:
            continue
        combined = holes + points
        if any(cross(combined[a], combined[b], point) == 0
               for a in range(len(combined)) for b in range(a + 1, len(combined))):
            continue
        points.append(point)
    return points


def build():
    write("2_edges", [(0, 0), (10, 0), (0, 10), (20, 20)], [(3, 2)])
    holes = distinct_points(random.Random(77), 12)
    write("3_wide", holes, distinct_trees(random.Random(78), 12, holes))
    rng = random.Random(20261126)
    holes = distinct_points(rng, 10)
    write("4_random", holes, distinct_trees(rng, 10, holes))
    holes = distinct_points(rng, 12)
    write("5_io", holes, distinct_trees(rng, 12, holes))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(800, 300), (200, 200), (200, 700), (600, 700)], [(400, 300), (600, 500), (800, 900)])
build()

rng = random.Random(19471208)
big_holes = distinct_points(rng, 100)
big_trees = distinct_trees(rng, 100, big_holes)
big_text = f"{len(big_holes)} {len(big_trees)}\n"
big_text += "".join(f"{x_coord} {y_coord}\n" for x_coord, y_coord in big_holes)
big_text += "".join(f"{x_coord} {y_coord}\n" for x_coord, y_coord in big_trees)
Path("/tmp/CEOI08A_big.txt").write_text(big_text)
