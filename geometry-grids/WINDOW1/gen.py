#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def point_inside(px2, py2, vxs, vys):
    n = len(vxs)
    inside = False
    for i in range(n):
        j = (i + 1) % n
        y1 = 2 * vys[i]
        y2 = 2 * vys[j]
        if (y1 > py2) != (y2 > py2) and 2 * vxs[i] > px2:
            inside = not inside
    return inside


def oracle(win, poly):
    x1, y1, x2, y2 = win
    left, right = sorted((x1, x2))
    bottom, top = sorted((y1, y2))
    if left >= right or bottom >= top:
        return 0
    vxs = [p[0] for p in poly]
    vys = [p[1] for p in poly]
    filled = set()
    for cx in range(left, right):
        for cy in range(bottom, top):
            if point_inside(2 * cx + 1, 2 * cy + 1, vxs, vys):
                filled.add((cx, cy))
    seen = set()
    parts = 0
    for cell in filled:
        if cell in seen:
            continue
        parts += 1
        seen.add(cell)
        queue = deque([cell])
        while queue:
            cx, cy = queue.popleft()
            for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                if (nx, ny) in filled and (nx, ny) not in seen:
                    seen.add((nx, ny))
                    queue.append((nx, ny))
    return parts


STEPS = ((1, 0), (-1, 0), (0, 1), (0, -1))
DIAGONALS = ((1, 1), (1, -1), (-1, 1), (-1, -1))


def no_corner_touch(cand, cells):
    for dx, dy in DIAGONALS:
        far = (cand[0] + dx, cand[1] + dy)
        bridge_x = (cand[0] + dx, cand[1])
        bridge_y = (cand[0], cand[1] + dy)
        if far in cells and bridge_x not in cells and bridge_y not in cells:
            return False
    return True


def cells_to_vertices(cells):
    directed = {}
    for cx, cy in cells:
        edges = (
            ((cx, cy), (cx + 1, cy), (cx, cy - 1)),
            ((cx + 1, cy), (cx + 1, cy + 1), (cx + 1, cy)),
            ((cx + 1, cy + 1), (cx, cy + 1), (cx, cy + 1)),
            ((cx, cy + 1), (cx, cy), (cx - 1, cy)),
        )
        for start, end, neighbour in edges:
            if neighbour not in cells:
                if start in directed:
                    return None
                directed[start] = end
    start = next(iter(directed))
    vertices = []
    current = start
    while True:
        vertices.append(current)
        current = directed[current]
        if current == start:
            break
    if len(vertices) != len(directed):
        return None
    return vertices


def grow_cells(rng, width, height, target, branching):
    start_cell = (rng.randrange(width), rng.randrange(height))
    cells = {start_cell}
    end = start_cell
    while len(cells) < target:
        options = []
        bases = tuple(cells) if branching else (end,)
        for base in bases:
            for dx, dy in STEPS:
                cand = (base[0] + dx, base[1] + dy)
                if not (0 <= cand[0] < width and 0 <= cand[1] < height):
                    continue
                if cand in cells:
                    continue
                if not no_corner_touch(cand, cells):
                    continue
                touching = [(cand[0] + ax, cand[1] + ay)
                            for ax, ay in STEPS
                            if (cand[0] + ax, cand[1] + ay) in cells]
                if not branching and touching != [end]:
                    continue
                options.append(cand)
        if not options:
            break
        end = rng.choice(options)
        cells.add(end)
    return cells


def snake_poly(rng, width, height, target):
    best = None
    for _ in range(20):
        cells = grow_cells(rng, width, height, target, False)
        if best is None or len(cells) > len(best):
            best = cells
        if len(best) >= target:
            break
    vertices = cells_to_vertices(best)
    assert vertices is not None
    return vertices


def branch_poly(rng, width, height, target):
    for _ in range(30):
        cells = grow_cells(rng, width, height, target, True)
        if len(cells) < 4:
            continue
        vertices = cells_to_vertices(cells)
        if vertices is not None:
            return vertices
    return snake_poly(rng, width, height, target)


def comb_poly(rng, width, height, top_bar):
    cells = set()
    rows = (height - 2, height - 1) if top_bar else (0, 1)
    for cx in range(width):
        for cy in rows:
            cells.add((cx, cy))
    for cx in range(1, width - 1):
        if rng.random() < 0.5:
            continue
        teeth = range(0, height - 2) if top_bar else range(2, height)
        for cy in teeth:
            cells.add((cx, cy))
    vertices = cells_to_vertices(cells)
    assert vertices is not None
    return vertices


SQUARE = [(0, 0), (2, 0), (2, 2), (0, 2)]

SAMPLE_INPUT = """1
0 5 8 1
24
0 0
4 0
4 2
5 2
5 0
7 0
7 3
3 3
3 2
2 2
2 4
1 4
1 5
2 5
2 6
3 6
3 5
4 5
4 6
5 6
5 4
7 4
7 7
0 7
"""
SAMPLE_POLY = []
for line in SAMPLE_INPUT.splitlines()[3:]:
    x, y = line.split()
    SAMPLE_POLY.append((int(x), int(y)))

assert oracle((0, 5, 8, 1), SAMPLE_POLY) == 2
assert oracle((0, 2, 2, 0), SQUARE) == 1
assert oracle((1, 2, 3, 0), SQUARE) == 1
assert oracle((2, 2, 4, 0), SQUARE) == 0
assert oracle((5, 5, 5, 0), SQUARE) == 0
assert oracle((0, 5, 5, 0), SQUARE) == 1


def write_raw(name, input_text, answers):
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(
        "\n".join(str(answer) for answer in answers) + "\n")


def write(name, cases):
    lines = [str(len(cases))]
    answers = []
    for win, poly in cases:
        lines.append("%d %d %d %d" % win)
        lines.append(str(len(poly)))
        for x, y in poly:
            lines.append("%d %d" % (x, y))
        answers.append(oracle(win, poly))
    write_raw(name, "\n".join(lines) + "\n", answers)


def build():
    write_raw("1_sample", SAMPLE_INPUT, [2])

    rng = random.Random(20261124)
    big = branch_poly(rng, 24, 24, 90)
    narrow = snake_poly(rng, 10, 10, 12)
    comb_up = comb_poly(rng, 9, 9, False)
    comb_down = comb_poly(rng, 9, 9, True)
    edges = [
        ((5, 0, 5, 10), SQUARE),
        ((0, 5, 10, 5), SQUARE),
        ((20, 20, 30, 30), SQUARE),
        ((0, 2, 2, 0), SQUARE),
        ((2, 2, 4, 0), SQUARE),
        ((0, 1, 1, 0), SQUARE),
        ((1, 2, 3, 0), SQUARE),
        ((0, 5, 5, 0), SQUARE),
        ((0, 24, 24, 0), big),
        ((0, 10, 10, 0), narrow),
        ((0, 9, 9, 3), comb_up),
        ((0, 6, 9, 0), comb_down),
        ((0, 9, 9, 0), comb_up),
    ]
    write("2_edges", edges)

    wide = [
        ((0, 60, 60, 0), snake_poly(rng, 50, 50, 220)),
        ((25, 26, 26, 25), snake_poly(rng, 30, 30, 40)),
        ((0, 10000, 10000, 0), SQUARE),
        ((0, 8, 8, 0), SQUARE),
    ]
    write("3_wide", wide)

    random_cases = []
    for case_index in range(120):
        width = rng.randint(4, 14)
        height = rng.randint(4, 14)
        if case_index % 3 == 0:
            poly = snake_poly(rng, width, height,
                              rng.randint(2, min(width * height, 28)))
        elif case_index % 3 == 1:
            poly = branch_poly(rng, width, height,
                               rng.randint(2, min(width * height, 28)))
        else:
            poly = comb_poly(rng, width, height, rng.random() < 0.5)
        wx1 = rng.randint(0, width)
        wy1 = rng.randint(0, height)
        wx2 = rng.randint(0, width)
        wy2 = rng.randint(0, height)
        random_cases.append(((wx1, wy1, wx2, wy2), poly))
    write("4_random", random_cases)

    pool = []
    for pool_index in range(24):
        if pool_index % 3 == 0:
            poly = snake_poly(rng, 6, 6, rng.randint(2, 8))
        elif pool_index % 3 == 1:
            poly = branch_poly(rng, 6, 6, rng.randint(2, 8))
        else:
            poly = comb_poly(rng, 6, 6, rng.random() < 0.5)
        pool.append(((rng.randint(0, 6), rng.randint(0, 6),
                      rng.randint(0, 6), rng.randint(0, 6)), poly))
    answers = [oracle(win, poly) for win, poly in pool]
    lines = []
    io_answers = []
    for _ in range(200000):
        pick = rng.randrange(len(pool))
        win, poly = pool[pick]
        lines.append("%d %d %d %d" % win)
        lines.append(str(len(poly)))
        for x, y in poly:
            lines.append("%d %d" % (x, y))
        io_answers.append(answers[pick])
    write_raw("5_io", "200000\n" + "\n".join(lines) + "\n", io_answers)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
