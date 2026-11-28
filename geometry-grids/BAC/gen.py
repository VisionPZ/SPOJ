import math
import os
import random
from fractions import Fraction


def half_plane_lines(sites, site_index, plate_width, plate_height):
    site_x, site_y = sites[site_index]
    lines = [
        (-1, 0, 0),
        (1, 0, plate_width),
        (0, -1, 0),
        (0, 1, plate_height),
    ]
    for other_index, (other_x, other_y) in enumerate(sites):
        if other_index == site_index:
            continue
        lines.append((
            2 * (other_x - site_x),
            2 * (other_y - site_y),
            other_x * other_x + other_y * other_y - site_x * site_x - site_y * site_y,
        ))
    return lines


def cross_product(origin, first, second):
    return (first[0] - origin[0]) * (second[1] - origin[1]) - (first[1] - origin[1]) * (second[0] - origin[0])


def convex_area(points):
    ordered = sorted(set(points))
    lower = []
    for point in ordered:
        while len(lower) >= 2 and cross_product(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper = []
    for point in reversed(ordered):
        while len(upper) >= 2 and cross_product(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    hull = lower[:-1] + upper[:-1]
    if len(hull) < 3:
        return Fraction(0)
    doubled = Fraction(0)
    for index in range(len(hull)):
        first_x, first_y = hull[index]
        second_x, second_y = hull[(index + 1) % len(hull)]
        doubled += first_x * second_y - second_x * first_y
    return abs(doubled) / 2


def cell_area_by_intersections(sites, site_index, plate_width, plate_height):
    lines = half_plane_lines(sites, site_index, plate_width, plate_height)
    vertices = []
    line_count = len(lines)
    for first in range(line_count):
        coef_a1, coef_b1, bound1 = lines[first]
        for second in range(first + 1, line_count):
            coef_a2, coef_b2, bound2 = lines[second]
            determinant = coef_a1 * coef_b2 - coef_a2 * coef_b1
            if determinant == 0:
                continue
            numerator_x = bound1 * coef_b2 - bound2 * coef_b1
            numerator_y = coef_a1 * bound2 - coef_a2 * bound1
            if determinant < 0:
                determinant = -determinant
                numerator_x = -numerator_x
                numerator_y = -numerator_y
            feasible = True
            for coef_a, coef_b, bound in lines:
                if coef_a * numerator_x + coef_b * numerator_y > bound * determinant:
                    feasible = False
                    break
            if feasible:
                vertices.append((Fraction(numerator_x, determinant), Fraction(numerator_y, determinant)))
    return convex_area(vertices)


def format_area(area):
    scaled = area * 100
    whole = scaled.numerator // scaled.denominator
    remainder = scaled - whole
    if remainder > Fraction(1, 2) or (remainder == Fraction(1, 2) and whole % 2 == 1):
        whole += 1
    return f"{whole // 100}.{whole % 100:02d}"


def oracle(cases):
    result = []
    for plate_width, plate_height, sites in cases:
        areas = []
        for site_index in range(len(sites)):
            areas.append(cell_area_by_intersections(sites, site_index, plate_width, plate_height))
        assert sum(areas) == plate_width * plate_height, (plate_width, plate_height, sum(areas))
        order = sorted(range(len(sites)), key=lambda index: (-areas[index], index))
        for site_index in order:
            number_text = format_area(areas[site_index])
            result.append(f"{site_index + 1:03d}{number_text:>14}\n")
        result.append("\n")
    return "".join(result)


def input_text(cases):
    body = []
    for plate_width, plate_height, sites in cases:
        body.append(f"{plate_width} {plate_height}\n")
        body.append(f"{len(sites)}\n")
        for site_x, site_y in sites:
            body.append(f"{site_x} {site_y}\n")
        body.append("\n")
    body.append("0 0\n")
    return "".join(body)


def write_case(name, cases):
    with open(f"in/{name}.txt", "w") as handle:
        handle.write(input_text(cases))
    with open(f"out/{name}.out", "w") as handle:
        handle.write(oracle(cases))


assert cell_area_by_intersections([(0, 0)], 0, 10, 10) == 100
assert cell_area_by_intersections([(0, 0), (10, 10)], 0, 10, 10) == 50
assert cell_area_by_intersections([(5, 5), (0, 0)], 0, 10, 10) == Fraction(175, 2)
assert cell_area_by_intersections([(0, 0), (10, 0), (10, 10), (0, 10)], 2, 10, 10) == 25
assert sum(cell_area_by_intersections(
    [(x, y) for x in (0, 5, 10) for y in (0, 5, 10)], index, 10, 10)
    for index in range(9)) == 100

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

sample_cases = [(10, 10, [(5, 5), (0, 0)])]

edge_cases = [
    (1, 1, [(0, 0)]),
    (1, 1, [(0, 0), (1, 1)]),
    (2, 3, [(0, 0)]),
    (10, 10, [(0, 0), (10, 10)]),
    (10, 10, [(0, 0), (10, 0), (10, 10), (0, 10)]),
    (10, 10, [(5, 5), (5, 0), (5, 10), (0, 5), (10, 5)]),
    (1000, 1000, [(0, 0), (1000, 1000)]),
    (1000, 1, [(0, 0), (500, 1), (1000, 0)]),
    (7, 9, [(1, 1), (6, 8), (3, 4)]),
    (10, 10, [(0, 0), (5, 1), (10, 2), (1, 5), (6, 6), (10, 7), (2, 10), (7, 10), (9, 4)]),
]

wide_rng = random.Random(13579)
wide_cases = []
for _ in range(3):
    wide_sites = set()
    while len(wide_sites) < 100:
        wide_sites.add((wide_rng.randint(0, 1000), wide_rng.randint(0, 1000)))
    wide_cases.append((1000, 1000, sorted(wide_sites)))

rng = random.Random(20261123)
random_cases = []
for _ in range(16):
    plate_width = rng.randint(1, 1000)
    plate_height = rng.randint(1, 1000)
    available = (plate_width + 1) * (plate_height + 1)
    sample_count = min(rng.randint(1, 100), available)
    sites = set()
    while len(sites) < sample_count:
        sites.add((rng.randint(0, plate_width), rng.randint(0, plate_height)))
    random_cases.append((plate_width, plate_height, sorted(sites)))

io_cases = []
io_rng = random.Random(424242)
for case_index in range(20000):
    plate_width = io_rng.randint(1, 1000)
    plate_height = io_rng.randint(1, 1000)
    site_count = io_rng.randint(1, 3)
    sites = set()
    while len(sites) < site_count:
        sites.add((io_rng.randint(0, plate_width), io_rng.randint(0, plate_height)))
    io_cases.append((plate_width, plate_height, sorted(sites)))
for case_index in range(12):
    sites = set()
    while len(sites) < 100:
        sites.add((io_rng.randint(0, 1000), io_rng.randint(0, 1000)))
    io_cases.append((1000, 1000, sorted(sites)))

write_case("1_sample", sample_cases)
write_case("2_edges", edge_cases)
write_case("3_wide", wide_cases)
write_case("4_random", random_cases)
write_case("5_io", io_cases)

print("generated 5 test pairs; io cases:", len(io_cases))
