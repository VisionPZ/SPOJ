#!/usr/bin/env python3
from functools import lru_cache
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def make_triangulation(vertex_count, rng):
    remaining = list(range(vertex_count))
    triangles = []
    while len(remaining) > 3:
        size = len(remaining)
        pos = rng.randrange(size)
        previous = remaining[(pos - 1) % size]
        current = remaining[pos]
        following = remaining[(pos + 1) % size]
        triangles.append(tuple(sorted((previous, current, following))))
        remaining.pop(pos)
    triangles.append(tuple(sorted(remaining)))
    return triangles


def fan_triangulation(vertex_count):
    return [(0, i, i + 1) for i in range(1, vertex_count - 1)]


def check_triangulation(vertex_count, triangles):
    assert len(triangles) == vertex_count - 2
    edge_use = {}
    for tri in triangles:
        assert len(set(tri)) == 3
        for first, second in ((tri[0], tri[1]), (tri[0], tri[2]), (tri[1], tri[2])):
            edge = tuple(sorted((first, second)))
            edge_use[edge] = edge_use.get(edge, 0) + 1
    assert all(use in (1, 2) for use in edge_use.values())
    for vertex in range(vertex_count):
        edge = tuple(sorted((vertex, (vertex + 1) % vertex_count)))
        assert edge_use.get(edge) == 1
    assert sum(use == 2 for use in edge_use.values()) == vertex_count - 3


def dual_adjacency(triangles):
    adjacency = [[] for _ in triangles]
    edge_owner = {}
    for index, tri in enumerate(triangles):
        for first, second in ((tri[0], tri[1]), (tri[0], tri[2]), (tri[1], tri[2])):
            edge = tuple(sorted((first, second)))
            if edge in edge_owner:
                other = edge_owner[edge]
                adjacency[index].append(other)
                adjacency[other].append(index)
            else:
                edge_owner[edge] = index
    assert sum(len(neighbours) for neighbours in adjacency) == 2 * (len(triangles) - 1)
    return adjacency


def oracle(vertex_count, triangles):
    check_triangulation(vertex_count, triangles)
    adjacency = dual_adjacency(triangles)
    if len(adjacency[0]) <= 1:
        return "YES"
    parent = [-1] * len(triangles)
    parent[0] = 0
    order = []
    stack = [0]
    while stack:
        node = stack.pop()
        order.append(node)
        for neighbour in adjacency[node]:
            if neighbour != parent[node]:
                parent[neighbour] = node
                stack.append(neighbour)
    grundy = [0] * len(triangles)
    for node in reversed(order):
        value = 1
        for neighbour in adjacency[node]:
            if parent[neighbour] == node:
                value ^= grundy[neighbour]
        grundy[node] = value
    combined = 0
    for neighbour in adjacency[0]:
        combined ^= grundy[neighbour]
    return "YES" if combined == 1 else "NO"


def brute_game(triangles):
    adjacency = dual_adjacency(triangles)
    total = len(triangles)
    full = (1 << total) - 1

    @lru_cache(maxsize=None)
    def winning(state):
        for node in range(total):
            if state >> node & 1:
                degree = sum(1 for neighbour in adjacency[node] if state >> neighbour & 1)
                if degree <= 1:
                    if node == 0:
                        return True
                    if not winning(state ^ (1 << node)):
                        return True
        return False

    return "YES" if winning(full) else "NO"


def reorder(triangles, black_index):
    return [triangles[black_index]] + [
        tri for index, tri in enumerate(triangles) if index != black_index
    ]


def worked_example():
    adjacency = dual_adjacency(SAMPLE_TRIS)
    return "\n".join([
        f"black neighbours: {len(adjacency[0])}",
        f"non-black triangles: {len(SAMPLE_TRIS) - 1}",
        f"answer: {oracle(SAMPLE_N, SAMPLE_TRIS)}",
    ])


def write(name, cases):
    lines = [str(len(cases))]
    answers = []
    for index, (vertex_count, triangles) in enumerate(cases):
        if index:
            lines.append("")
        lines.append(str(vertex_count))
        for tri in triangles:
            lines.append(" ".join(str(vertex) for vertex in tri))
        answers.append(oracle(vertex_count, triangles))
    (ROOT / "in" / f"{name}.txt").write_text("\n".join(lines) + "\n")
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


SAMPLE_N = 6
SAMPLE_TRIS = [(0, 1, 2), (2, 4, 3), (4, 2, 0), (0, 5, 4)]
assert oracle(SAMPLE_N, SAMPLE_TRIS) == "YES"
assert brute_game(SAMPLE_TRIS) == "YES"
assert oracle(4, fan_triangulation(4)) == "YES"
assert oracle(5, reorder(fan_triangulation(5), 1)) == "NO"
assert oracle(5, fan_triangulation(5)) == "YES"

check_rng = random.Random(4242)
for size in range(4, 12):
    for _ in range(30):
        tris = make_triangulation(size, check_rng)
        black = check_rng.randrange(len(tris))
        check_triangulation(size, tris)
        chosen = reorder(tris, black)
        assert oracle(size, chosen) == brute_game(chosen)


def build():
    edges = [
        (4, fan_triangulation(4)),
        (4, reorder(fan_triangulation(4), 1)),
        (5, reorder(fan_triangulation(5), 1)),
        (5, fan_triangulation(5)),
        (6, reorder(fan_triangulation(6), 1)),
        (7, reorder(fan_triangulation(7), 1)),
        (7, fan_triangulation(7)),
        (8, fan_triangulation(8)),
        (9, fan_triangulation(9)),
    ]
    for size, tris in edges:
        check_triangulation(size, tris)
        assert oracle(size, tris) == brute_game(tris)
    write("2_edges", edges)

    wide_rng = random.Random(202)
    wide = [
        (50000, fan_triangulation(50000)),
        (50000, reorder(fan_triangulation(50000), 25000)),
        (49999, reorder(fan_triangulation(49999), 25000)),
        (49999, make_triangulation(49999, wide_rng)),
        (50000, make_triangulation(50000, wide_rng)),
    ]
    for size, tris in wide:
        check_triangulation(size, tris)
    write("3_wide", wide)

    random_rng = random.Random(303)
    random_cases = []
    for _ in range(24):
        size = random_rng.randint(4, 4000)
        tris = make_triangulation(size, random_rng)
        random_cases.append((size, reorder(tris, random_rng.randrange(len(tris)))))
    write("4_random", random_cases)

    io_small = fan_triangulation(4)
    io_cases = []
    for case_index in range(120000):
        tris = io_small if case_index % 2 == 0 else reorder(io_small, 1)
        io_cases.append((4, tris))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(SAMPLE_N, SAMPLE_TRIS)])
build()
