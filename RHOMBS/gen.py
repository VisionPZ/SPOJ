#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

STEP_VECTOR = {
    1: (1, 0),
    2: (0, 1),
    3: (-1, 1),
    4: (-1, 0),
    5: (0, -1),
    6: (1, -1),
}
VECTOR_STEP = {vector: step for step, vector in STEP_VECTOR.items()}


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        side_count = int(tokens[cursor]); cursor += 1
        position_x = 0
        position_y = 0
        double_area = 0
        count_a = 0
        count_c = 0
        for _ in range(side_count):
            direction = int(tokens[cursor]); cursor += 1
            length = int(tokens[cursor]); cursor += 1
            step_x, step_y = STEP_VECTOR[direction]
            for _ in range(length):
                next_x = position_x + step_x
                next_y = position_y + step_y
                double_area += position_x * next_y - next_x * position_y
                if direction == 1:
                    count_c += position_x
                elif direction == 4:
                    count_c += 1 - position_x
                elif direction == 2:
                    count_a -= position_y
                elif direction == 5:
                    count_a += position_y - 1
                position_x, position_y = next_x, next_y
        assert (position_x, position_y) == (0, 0)
        assert double_area >= 0 and double_area % 2 == 0
        count_b = double_area // 2 - count_a - count_c
        answers.append(f"{count_a} {count_b} {count_c}")
    return "\n".join(answers) + "\n"


def triangle_edges(triangle):
    a, b, kind = triangle
    if kind == 0:
        return [((a, b), (a + 1, b)),
                ((a + 1, b), (a, b + 1)),
                ((a, b + 1), (a, b))]
    return [((a + 1, b), (a + 1, b + 1)),
            ((a + 1, b + 1), (a, b + 1)),
            ((a, b + 1), (a + 1, b))]


def triangle_neighbors(triangle):
    a, b, kind = triangle
    if kind == 0:
        return [((a, b - 1, 1), 0), ((a - 1, b, 1), 1), ((a, b, 1), 2)]
    return [((a, b + 1, 0), 0), ((a + 1, b, 0), 1), ((a, b, 0), 2)]


def boundary_sides(triangles):
    edge_owners = {}
    for triangle in triangles:
        for point_from, point_to in triangle_edges(triangle):
            key = tuple(sorted((point_from, point_to)))
            edge_owners.setdefault(key, []).append((point_from, point_to))
    boundary = [pair[0] for pair in edge_owners.values() if len(pair) == 1]
    following = {}
    for point_from, point_to in boundary:
        assert point_from not in following
        following[point_from] = point_to
    start = boundary[0][0]
    current = start
    sides = []
    walked_edges = 0
    while True:
        nxt = following[current]
        vector = (nxt[0] - current[0], nxt[1] - current[1])
        direction = VECTOR_STEP[vector]
        if sides and sides[-1][0] == direction:
            sides[-1][1] += 1
        else:
            sides.append([direction, 1])
        current = nxt
        walked_edges += 1
        if current == start:
            break
    assert walked_edges == len(boundary)
    return [(direction, length) for direction, length in sides]


def build_region(rng, rhomb_target):
    triangles = {(0, 0, 0), (0, 0, 1)}
    families = [2]
    for _ in range(rhomb_target - 1):
        candidates = []
        for triangle in list(triangles):
            for added, shared_family in triangle_neighbors(triangle):
                if added in triangles:
                    continue
                for partner, rhomb_family in triangle_neighbors(added):
                    if partner in triangles or partner == triangle:
                        continue
                    if rhomb_family == shared_family:
                        continue
                    candidates.append((added, partner, rhomb_family))
        rng.shuffle(candidates)
        for added, partner, rhomb_family in candidates:
            enlarged = triangles | {added, partner}
            try:
                boundary_sides(enlarged)
            except (AssertionError, KeyError):
                continue
            triangles = enlarged
            families.append(rhomb_family)
            break
    return triangles, families


def staircase_region(cell_count):
    triangles = set()
    for cell_index in range(cell_count):
        cell_x = (cell_index + 1) // 2
        cell_y = cell_index // 2
        triangles.add((cell_x, cell_y, 0))
        triangles.add((cell_x, cell_y, 1))
    return triangles


def case_text(sides):
    lines = [str(len(sides))]
    lines.extend(f"{direction} {length}" for direction, length in sides)
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(case_text(sides) for sides in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_SIDES = [(1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2)]
SAMPLE_INPUT = ("1\n6 \n1 2 \n2 2 \n3 2 \n4 2 \n5 2 \n6 2 \n")

assert oracle(SAMPLE_INPUT) == "4 4 4\n"
assert oracle("1\n4\n2 1\n3 1\n5 1\n6 1\n") == "1 0 0\n"
assert oracle("1\n4\n1 1\n2 1\n4 1\n5 1\n") == "0 1 0\n"
assert oracle("1\n4\n1 1\n3 1\n4 1\n6 1\n") == "0 0 1\n"

for seed in range(40):
    rng = random.Random(seed)
    triangles, families = build_region(rng, rng.randint(1, 10))
    sides = boundary_sides(triangles)
    expected = f"{families.count(0)} {families.count(2)} {families.count(1)}\n"
    assert oracle("1\n" + case_text(sides)) == expected


def build():
    single_a = [(2, 1), (3, 1), (5, 1), (6, 1)]
    single_b = [(1, 1), (2, 1), (4, 1), (5, 1)]
    single_c = [(1, 1), (3, 1), (4, 1), (6, 1)]
    small_b = staircase_region(4)
    write("2_edges", [
        single_a,
        single_b,
        single_c,
        boundary_sides(small_b),
        [(1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1)],
        [(1, 400), (2, 400), (3, 400), (4, 400), (5, 400), (6, 400)],
    ])

    write("3_wide", [
        [(1, 4000), (2, 4000), (3, 4000), (4, 4000), (5, 4000), (6, 4000)],
        boundary_sides(staircase_region(5000)),
        [(1, 15000), (2, 15000), (4, 15000), (5, 15000)],
    ])

    rng = random.Random(2026)
    random_cases = []
    for case_index in range(24):
        rhomb_target = 1 + (case_index * 37) % 180
        triangles, _ = build_region(rng, rhomb_target)
        random_cases.append(boundary_sides(triangles))
    write("4_random", random_cases)

    write("5_io", [single_a] * 20000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE_SIDES])
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
build()
