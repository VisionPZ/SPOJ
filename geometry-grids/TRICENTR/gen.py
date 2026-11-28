#!/usr/bin/env python3
import math
import random


def reference(side_a, dist_a, dist_b, dist_c):
    area = 1.5 * side_a * dist_a
    side_b = (2.0 * area) / (3.0 * dist_b)
    side_c = (2.0 * area) / (3.0 * dist_c)
    circum = side_a * side_b * side_c / (4.0 * area)
    oh_sq = 9.0 * circum * circum - (side_a * side_a + side_b * side_b + side_c * side_c)
    if oh_sq < 0.0:
        oh_sq = 0.0
    gh = (2.0 / 3.0) * math.sqrt(oh_sq)
    return "%.3f %.3f" % (area, gh)


def solution_formula(side_a, dist_a, dist_b, dist_c):
    area = 1.5 * side_a * dist_a
    side_b = side_a * dist_a / dist_b
    side_c = side_a * dist_a / dist_c
    circum = side_a * side_b * side_c / (4.0 * area)
    oh_sq = 9.0 * circum * circum - (side_a * side_a + side_b * side_b + side_c * side_c)
    if oh_sq < 0.0:
        oh_sq = 0.0
    gh = (2.0 / 3.0) * math.sqrt(oh_sq)
    return "%.3f %.3f" % (area, gh)


assert reference(3.0, 0.8660254038, 0.8660254038, 0.8660254038) == "3.897 0.000"
assert reference(657.8256599140, 151.6154399062, 213.5392629932, 139.4878846649) == "149604.790 150.275"
assert reference(2.0, 0.5773502692, 0.5773502692, 0.5773502692) == "1.732 0.000"


def decimal_text(value):
    return "%.10f" % value


def from_sides(side_a, side_b, side_c):
    semi = (side_a + side_b + side_c) / 2.0
    area_sq = semi * (semi - side_a) * (semi - side_b) * (semi - side_c)
    area = math.sqrt(area_sq) if area_sq > 0.0 else 0.0
    return (side_a, 2.0 * area / (3.0 * side_a),
            2.0 * area / (3.0 * side_b),
            2.0 * area / (3.0 * side_c))


def write_verbatim(name, input_text, output_text):
    with open("in/" + name + ".txt", "w") as input_file:
        input_file.write(input_text)
    with open("out/" + name + ".out", "w") as output_file:
        output_file.write(output_text)


def write_generated(name, rows):
    with open("in/" + name + ".txt", "w") as input_file:
        input_file.write("%d\n" % len(rows))
        for row in rows:
            input_file.write(" ".join(decimal_text(value) for value in row) + "\n")
    with open("out/" + name + ".out", "w") as output_file:
        for row in rows:
            values = tuple(float(decimal_text(value)) for value in row)
            expected = reference(*values)
            assert expected == solution_formula(*values), (name, row, expected, solution_formula(*values))
            output_file.write(expected + "\n")


sample_input = ("2\n"
                "3.0 0.8660254038 0.8660254038 0.8660254038\n"
                "657.8256599140 151.6154399062 213.5392629932 139.4878846649\n")
sample_output = "3.897 0.000\n149604.790 150.275\n"
assert reference(3.0, 0.8660254038, 0.8660254038, 0.8660254038) + "\n" + reference(657.8256599140, 151.6154399062, 213.5392629932, 139.4878846649) + "\n" == sample_output
write_verbatim("1_sample", sample_input, sample_output)

edge_triangles = [
    (1.0, 1.0, 1.0),
    (3.0, 4.0, 5.0),
    (5.0, 5.0, 6.0),
    (7.0, 8.0, 13.0),
    (10.0, 10.0, 19.0),
    (1000.0, 1000.0, 1000.0),
    (0.001, 0.001, 0.001),
    (2.0, 3.0, 4.0),
    (9.0, 40.0, 41.0),
    (13.0, 14.0, 15.0),
    (100.0, 101.0, 150.0),
    (0.5, 0.7, 1.1),
    (657.8256599140, 467.0641146337, 715.0192796245),
    (1.0, 1.0000000001, 1.0000000002),
]
write_generated("2_edges", [from_sides(*triangle) for triangle in edge_triangles])

wide_rng = random.Random(20240501)
wide_rows = []
for _ in range(120):
    scale = 10.0 ** wide_rng.uniform(-2.0, 4.0)
    sides = [scale * (1.0 + wide_rng.random() * 3.0) for _ in range(3)]
    sides.sort()
    if sides[0] + sides[1] <= sides[2]:
        sides[2] = (sides[0] + sides[1]) * 0.999
    wide_rows.append(from_sides(*sides))
write_generated("3_wide", wide_rows)

random_rng = random.Random(777331)
random_rows = []
for _ in range(500):
    scale = 10.0 ** random_rng.uniform(-2.0, 4.0)
    sides = [scale * (1.0 + random_rng.random() * 3.0) for _ in range(3)]
    sides.sort()
    if sides[0] + sides[1] <= sides[2]:
        sides[2] = (sides[0] + sides[1]) * 0.999
    random_rows.append(from_sides(*sides))
write_generated("4_random", random_rows)

io_rng = random.Random(31415926)
io_rows = []
for _ in range(1000):
    scale = 10.0 ** io_rng.uniform(-1.0, 4.0)
    sides = [scale * (1.0 + io_rng.random() * 3.0) for _ in range(3)]
    sides.sort()
    if sides[0] + sides[1] <= sides[2]:
        sides[2] = (sides[0] + sides[1]) * 0.999
    io_rows.append(from_sides(*sides))
write_generated("5_io", io_rows)
