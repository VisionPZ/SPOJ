#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def polygon_area(poly):
    total = 0.0
    for index, point in enumerate(poly):
        following = poly[(index + 1) % len(poly)]
        total += (following[0] - point[0]) * (point[1] + following[1]) / 2.0
    return abs(total)


def clip_half(poly, coord, bound, keep_greater):
    if not poly:
        return []
    result = []

    def inside(point):
        if keep_greater:
            return point[coord] >= bound - 1e-12
        return point[coord] <= bound + 1e-12

    def crossing(start, end):
        denominator = end[coord] - start[coord]
        if abs(denominator) < 1e-15:
            return end
        ratio = (bound - start[coord]) / denominator
        return (start[0] + ratio * (end[0] - start[0]),
                start[1] + ratio * (end[1] - start[1]))

    previous = poly[-1]
    previous_inside = inside(previous)
    for point in poly:
        point_inside = inside(point)
        if point_inside:
            if not previous_inside:
                result.append(crossing(previous, point))
            result.append(point)
        elif previous_inside:
            result.append(crossing(previous, point))
        previous = point
        previous_inside = point_inside
    return result


def shoelace_area(poly):
    if len(poly) < 3:
        return 0.0
    total = 0.0
    for index, point in enumerate(poly):
        following = poly[(index + 1) % len(poly)]
        total += point[0] * following[1] - following[0] * point[1]
    return abs(total) / 2.0


def intersection_area(poly, rect):
    low_x, low_y, high_x, high_y = rect
    clipped = clip_half(poly, 0, low_x, True)
    clipped = clip_half(clipped, 0, high_x, False)
    clipped = clip_half(clipped, 1, low_y, True)
    clipped = clip_half(clipped, 1, high_y, False)
    return shoelace_area(clipped)


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while True:
        vertex_count = int(tokens[cursor]); cursor += 1
        plot_count = int(tokens[cursor]); cursor += 1
        if vertex_count == 0 and plot_count == 0:
            break
        poly = []
        for _ in range(vertex_count):
            poly.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        rects = []
        for _ in range(plot_count):
            first_x = int(tokens[cursor]); first_y = int(tokens[cursor + 1])
            second_x = int(tokens[cursor + 2]); second_y = int(tokens[cursor + 3])
            cursor += 4
            rects.append((min(first_x, second_x), min(first_y, second_y),
                          max(first_x, second_x), max(first_y, second_y)))
        axis_aligned = all(
            first[0] == second[0] or first[1] == second[1]
            for first, second in zip(poly, poly[1:] + poly[:1]))
        if not axis_aligned:
            answers.append("NO")
            continue
        park_area = polygon_area(poly)
        plot_total = 0.0
        for rect in rects:
            rect_area = (rect[2] - rect[0]) * (rect[3] - rect[1])
            if abs(intersection_area(poly, rect) - rect_area) < 1e-7:
                plot_total += rect_area
        answers.append("YES" if abs(plot_total - park_area) < 1e-7 else "NO")
    return "\n".join(answers) + "\n"


def winding_inside(pos_x, pos_y, poly):
    angle = 0.0
    for index, point in enumerate(poly):
        following = poly[(index + 1) % len(poly)]
        vec_x1 = point[0] - pos_x
        vec_y1 = point[1] - pos_y
        vec_x2 = following[0] - pos_x
        vec_y2 = following[1] - pos_y
        angle += math.atan2(vec_x1 * vec_y2 - vec_y1 * vec_x2,
                            vec_x1 * vec_x2 + vec_y1 * vec_y2)
    return abs(abs(angle) - 2 * math.pi) < 1e-6


def brute_force(poly, rects):
    cells = set()
    low_x = min(point[0] for point in poly)
    high_x = max(point[0] for point in poly)
    low_y = min(point[1] for point in poly)
    high_y = max(point[1] for point in poly)
    for pos_x in range(low_x, high_x):
        for pos_y in range(low_y, high_y):
            if winding_inside(pos_x + 0.5, pos_y + 0.5, poly):
                cells.add((pos_x, pos_y))
    plot_cells = []
    for rect in rects:
        plot_cells.append({
            (pos_x, pos_y)
            for pos_x in range(rect[0], rect[2])
            for pos_y in range(rect[1], rect[3])
        })
    for mask in range(1 << len(plot_cells)):
        chosen = set()
        for index, cell_set in enumerate(plot_cells):
            if mask & (1 << index):
                chosen |= cell_set
        if chosen == cells:
            return "YES"
    return "NO"


def render(cases):
    blocks = []
    for poly, rects in cases:
        lines = [f"{len(poly)} {len(rects)}"]
        lines += [f"{x} {y}" for x, y in poly]
        lines += [f"{x1} {y1} {x2} {y2}" for x1, y1, x2, y2 in rects]
        blocks.append("\n".join(lines) + "\n")
    return "".join(blocks) + "0 0\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def comb_case(teeth, height, included=None):
    poly = [(0, 0), (2 * teeth, 0), (2 * teeth, 1)]
    for index in range(teeth - 1, -1, -1):
        poly.append((2 * index + 1, 1))
        poly.append((2 * index + 1, 1 + height))
        poly.append((2 * index, 1 + height))
        poly.append((2 * index, 1))
    tiles = [(0, 0, 2 * teeth, 1)]
    for index in range(teeth):
        for level in range(height):
            tiles.append((2 * index, 1 + level, 2 * index + 1, 2 + level))
    if included is None:
        rects = tiles
    else:
        rects = [tiles[index] for index in included]
    return poly, rects


SQUARE = [(0, 0), (0, 2), (2, 2), (2, 0)]
NEGATIVE_SQUARE = [(-2, -2), (-2, 0), (0, 0), (0, -2)]
TRIANGLE = [(0, 0), (4, 0), (2, 4)]
U_SHAPE = [(0, 0), (8, 0), (8, 8), (6, 8), (6, 2), (2, 2), (2, 8), (0, 8)]
U_TILES = [(0, 0, 8, 2), (0, 2, 2, 8), (6, 2, 8, 8)]

SAMPLE_INPUT = (
    "4 2\n0 0\n0 2\n2 2\n2 0\n1 0 0 2\n1 0 2 2\n\n"
    "3 1\n0 0\n2 2\n2 0\n0 0 1 1\n\n0 0\n"
)
SAMPLE_OUTPUT = "YES\nNO\n"

assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert abs(polygon_area(SQUARE) - 4.0) < 1e-9
assert abs(polygon_area(TRIANGLE) - 8.0) < 1e-9
assert oracle(render([comb_case(2, 2)])) == "YES\n"

cross_cases = []
cross_rng = random.Random(4242)
for _ in range(40):
    teeth = cross_rng.randint(1, 4)
    height = cross_rng.randint(1, 3)
    poly, tiles = comb_case(teeth, height)
    included = [index for index in range(len(tiles))
                if cross_rng.random() < 0.8]
    cross_cases.append((poly, [tiles[index] for index in included]))
cross_cases.append((U_SHAPE, U_TILES))
cross_cases.append((U_SHAPE, [(1, 4, 7, 6)]))
for poly, rects in cross_cases:
    text = render([(poly, rects)])
    assert oracle(text) == brute_force(poly, rects) + "\n", (poly, rects)

edges = [
    (SQUARE, [(0, 0, 2, 2)]),
    (TRIANGLE, [(0, 0, 1, 1)]),
    (SQUARE, [(0, 0, 3, 2)]),
    (U_SHAPE, [(1, 4, 7, 6)]),
    (SQUARE, [(0, 0, 1, 2), (1, 0, 2, 2)]),
    (SQUARE, []),
    (NEGATIVE_SQUARE, [(-2, -2, 0, 0)]),
    (U_SHAPE, U_TILES),
    (SQUARE, [(5, 5, 6, 6)]),
    (SQUARE, [(2, 2, 3, 3)]),
]

wide_full = comb_case(749, 4)
wide_partial = comb_case(749, 4,
                         included=list(range(len(comb_case(749, 4)[1]) - 1)))

rng = random.Random(20261125)
random_cases = []
for _ in range(30):
    teeth = rng.randint(3, 30)
    height = rng.randint(1, 3)
    poly, tiles = comb_case(teeth, height)
    included = [index for index in range(len(tiles))
                if rng.random() < rng.choice((0.5, 0.8, 1.0))]
    random_cases.append((poly, [tiles[index] for index in included]))
for _ in range(15):
    poly = SQUARE
    low_x = rng.randint(-3, 2)
    low_y = rng.randint(-3, 2)
    high_x = low_x + rng.randint(1, 3)
    high_y = low_y + rng.randint(1, 3)
    random_cases.append((poly, [(low_x, low_y, high_x, high_y)]))
for _ in range(10):
    random_cases.append((TRIANGLE, [(0, 0, 1, 1)]))

io_cases = [(SQUARE, []) for _ in range(50000)]

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
write("2_edges", edges)
write("3_wide", [wide_full, wide_partial])
write("4_random", random_cases)
write("5_io", io_cases)

Path("/tmp/HARDQ_big.txt").write_text(render([(SQUARE, []) for _ in range(200000)]))
Path("/tmp/HARDQ_io_big.txt").write_text(
    render([(SQUARE, [(0, 0, 2, 2)]) for _ in range(120000)]))
Path("/tmp/HARDQ_io_parse.txt").write_text(
    "\n\n".join(" 4  0 \n 0 0\n\n 0 2\n2 2  \n 2 0\n"
                for _ in range(150000)) + "\n0 0\n")

print("generated", len(edges) + 2 + len(random_cases) + len(io_cases), "cases")
