#!/usr/bin/env python3
import random
from itertools import combinations
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent


def make_triangulation(n, rng):
    remaining = list(range(n))
    triangles = []
    while len(remaining) > 3:
        pos = rng.randrange(len(remaining))
        count = len(remaining)
        prev = remaining[(pos - 1) % count]
        cur = remaining[pos]
        nxt = remaining[(pos + 1) % count]
        triangles.append(tuple(sorted((prev, cur, nxt))))
        remaining.pop(pos)
    triangles.append(tuple(sorted(remaining)))
    return triangles


def fan_triangulation(n):
    return [(0, i, i + 1) for i in range(1, n - 1)]


def check_triangulation(n, triangles):
    assert len(triangles) == n - 2
    edge_use = {}
    for tri in triangles:
        assert len(set(tri)) == 3
        for first, second in combinations(tri, 2):
            edge = tuple(sorted((first, second)))
            edge_use[edge] = edge_use.get(edge, 0) + 1
    assert all(use in (1, 2) for use in edge_use.values())
    for vertex in range(n):
        edge = tuple(sorted((vertex, (vertex + 1) % n)))
        assert edge_use.get(edge) == 1
    assert sum(1 for use in edge_use.values() if use == 2) == n - 3


def oracle(n, triangles):
    if n == 3:
        return 1
    reach_table = np.zeros((n, n), dtype=np.int64)
    offsets = np.arange(n)
    for start in range(n):
        rotated_max = np.array(
            [max((vertex - start) % n for vertex in tri) for tri in triangles],
            dtype=np.int64)
        rotated_max.sort()
        reach = (offsets - start) % n
        reach_table[start] = np.searchsorted(rotated_max, reach, side='right')
    best_confined = n + 1
    for mid in range(1, n - 1):
        left_idx = np.arange(mid, dtype=np.int64)
        right_idx = np.arange(mid + 1, n, dtype=np.int64)
        left = reach_table[left_idx, mid][:, None]
        right = reach_table[mid, right_idx][None, :]
        wrap = reach_table[right_idx[:, None], left_idx[None, :]].T
        confined = left + right + wrap
        best_confined = min(best_confined, int(confined.min()))
    answer = (n - 2) - best_confined
    assert 1 <= answer <= n - 2
    return answer


def cross_product(origin, first, second):
    return ((first[0] - origin[0]) * (second[1] - origin[1])
            - (first[1] - origin[1]) * (second[0] - origin[0]))


def interiors_meet(points, first_tri, second_tri):
    first = [points[v] for v in first_tri]
    second = [points[v] for v in second_tri]
    for tri, other in ((first, second), (second, first)):
        for edge in range(3):
            head = tri[edge]
            tail = tri[(edge + 1) % 3]
            inside = tri[(edge + 2) % 3]
            positive = cross_product(head, tail, inside) > 0
            if not any((cross_product(head, tail, point) != 0
                        and (cross_product(head, tail, point) > 0) == positive)
                       for point in other):
                return False
    return True


def brute_geometry(n, triangles):
    points = [(vertex, vertex * vertex) for vertex in range(n)]
    best = 0
    for elementary in combinations(range(n), 3):
        count = sum(interiors_meet(points, elementary, tri) for tri in triangles)
        best = max(best, count)
    return best


def write(name, cases):
    lines = [str(len(cases))]
    answers = []
    for index, (n, triangles) in enumerate(cases):
        if index:
            lines.append("")
        lines.append(str(n))
        for tri in triangles:
            lines.append(" ".join(str(vertex) for vertex in tri))
        answers.append(str(oracle(n, triangles)))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


SAMPLE_N = 6
SAMPLE_TRIS = [(0, 1, 2), (2, 3, 4), (0, 4, 5), (0, 2, 4)]
assert oracle(SAMPLE_N, SAMPLE_TRIS) == 4
check_triangulation(SAMPLE_N, SAMPLE_TRIS)

check_rng = random.Random(4242)
for size in range(3, 11):
    for _ in range(5):
        tris = make_triangulation(size, check_rng)
        check_triangulation(size, tris)
        assert oracle(size, tris) == brute_geometry(size, tris)


def build():
    edge_cases = [(3, [(0, 1, 2)]), (4, fan_triangulation(4)),
                  (5, fan_triangulation(5)), (7, fan_triangulation(7))]
    check_rng = random.Random(101)
    for size in (6, 10, 12):
        edge_cases.append((size, make_triangulation(size, check_rng)))
    for n, tris in edge_cases:
        check_triangulation(n, tris)
    write("2_edges", edge_cases)

    wide_rng = random.Random(202)
    wide = [(1000, fan_triangulation(1000)),
            (1000, make_triangulation(1000, wide_rng)),
            (1000, make_triangulation(1000, wide_rng))]
    for n, tris in wide:
        check_triangulation(n, tris)
    write("3_wide", wide)

    random_rng = random.Random(303)
    random_cases = []
    for _ in range(20):
        size = random_rng.randint(40, 260)
        random_cases.append((size, make_triangulation(size, random_rng)))
    write("4_random", random_cases)

    io_cases = [(3, [(0, 1, 2)]) for _ in range(150000)]
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(SAMPLE_N, SAMPLE_TRIS)])
build()
