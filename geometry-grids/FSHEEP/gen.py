import math
import os
import random

SAMPLE_IN = """1
6 5
2 2
4 4
6 6
-3 1
-1 -1
5 1
2 1
3 2
6 6
3 3
-3 0
"""
SAMPLE_OUT = "3\n"


def on_segment(first, second, point):
    cross = (second[0] - first[0]) * (point[1] - first[1]) - (second[1] - first[1]) * (point[0] - first[0])
    if cross != 0:
        return False
    return (min(first[0], second[0]) <= point[0] <= max(first[0], second[0])
            and min(first[1], second[1]) <= point[1] <= max(first[1], second[1]))


def ray_cast(polygon, point):
    if point == (0, 0):
        return True
    inside = False
    count = len(polygon)
    for i in range(count):
        first = polygon[i]
        second = polygon[(i + 1) % count]
        if on_segment(first, second, point):
            return True
        if (first[1] > point[1]) != (second[1] > point[1]):
            dx = second[0] - first[0]
            dy = second[1] - first[1]
            left = (point[1] - first[1]) * dx
            right = (point[0] - first[0]) * dy
            if dy > 0:
                if left > right:
                    inside = not inside
            else:
                if left < right:
                    inside = not inside
    return inside


def oracle(polygon, sheep):
    return sum(1 for point in sheep if ray_cast(polygon, point))


def star_polygon(count, rng, radius_low=4000, radius_high=30000):
    for _ in range(200):
        points = []
        for i in range(count):
            angle = 2.0 * math.pi * (i + rng.uniform(-0.2, 0.2)) / count
            radius = rng.uniform(radius_low, radius_high)
            x = int(round(radius * math.cos(angle)))
            y = int(round(radius * math.sin(angle)))
            if x == 0 and y == 0:
                x, y = 1, 0
            points.append((x, y))
        points.sort(key=lambda point: (math.atan2(point[1], point[0]) % (2.0 * math.pi), radius_sq(point)))
        polygon = []
        for point in points:
            if not polygon or point != polygon[-1]:
                polygon.append(point)
        if len(polygon) < 3:
            continue
        if all(polygon[i][0] * polygon[(i + 1) % len(polygon)][1]
               - polygon[i][1] * polygon[(i + 1) % len(polygon)][0] > 0
               for i in range(len(polygon))):
            return polygon
    raise RuntimeError("could not build a star-shaped polygon")


def radius_sq(point):
    return point[0] * point[0] + point[1] * point[1]


def edge_min_radius(polygon):
    best = None
    count = len(polygon)
    for i in range(count):
        first = polygon[i]
        second = polygon[(i + 1) % count]
        ax, ay = first
        bx, by = second
        dx = bx - ax
        dy = by - ay
        length_sq = dx * dx + dy * dy
        if length_sq:
            t = -(ax * dx + ay * dy) / float(length_sq)
            t = max(0.0, min(1.0, t))
            px = ax + t * dx
            py = ay + t * dy
            dist = math.hypot(px, py)
            if best is None or dist < best:
                best = dist
    return best


def radius(point):
    return math.hypot(point[0], point[1])


def format_case(polygon, sheep):
    lines = ["%d %d" % (len(polygon), len(sheep))]
    lines.extend("%d %d" % point for point in polygon)
    lines.extend("%d %d" % point for point in sheep)
    return "\n".join(lines) + "\n"


def emit(name, cases):
    with open("in/%s.txt" % name, "w") as handle:
        handle.write(str(len(cases)) + "\n")
        for polygon, sheep in cases:
            handle.write(format_case(polygon, sheep))
    with open("out/%s.out" % name, "w") as handle:
        for polygon, sheep in cases:
            handle.write(str(oracle(polygon, sheep)) + "\n")


def emit_unambiguous(name, cases):
    with open("in/%s.txt" % name, "w") as handle:
        handle.write(str(len(cases)) + "\n")
        for polygon, sheep, expected in cases:
            handle.write(format_case(polygon, sheep))
    with open("out/%s.out" % name, "w") as handle:
        for polygon, sheep, expected in cases:
            handle.write(str(expected) + "\n")


def unambiguous_case(count, rng, sheep_per_side):
    if count > 20000:
        polygon = star_polygon(count, rng, 25000, 31000)
    else:
        polygon = star_polygon(count, rng)
    low = edge_min_radius(polygon)
    high = max(radius(point) for point in polygon)
    sheep = []
    expected = 0
    for _ in range(sheep_per_side):
        angle = rng.uniform(0.0, 2.0 * math.pi)
        dist = rng.uniform(1.0, low * 0.9)
        sheep.append((int(round(dist * math.cos(angle))), int(round(dist * math.sin(angle)))))
        expected += 1
    for _ in range(sheep_per_side):
        angle = rng.uniform(0.0, 2.0 * math.pi)
        dist = rng.uniform(high * 1.1, high * 1.4)
        sheep.append((int(round(dist * math.cos(angle))), int(round(dist * math.sin(angle)))))
    return polygon, sheep, expected


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    with open("in/1_sample.txt", "w") as handle:
        handle.write(SAMPLE_IN)
    with open("out/1_sample.out", "w") as handle:
        handle.write(SAMPLE_OUT)
    assert oracle([(2, 2), (4, 4), (6, 6), (-3, 1), (-1, -1), (5, 1)],
                  [(2, 1), (3, 2), (6, 6), (3, 3), (-3, 0)]) == 3

    square = [(1, -1), (1, 1), (-1, 1), (-1, -1)]
    assert oracle(square, [(0, 0), (2, 0), (1, 0)]) == 2
    triangle = [(0, 1), (-1, -1), (1, -1)]
    assert oracle(triangle, [(0, 0), (0, 2)]) == 1
    assert oracle(triangle, []) == 0

    radial = [(2, 0), (1, 0), (0, 2), (-2, 0), (0, -2)]
    assert oracle(radial, [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1)]) == 4
    radial_near = [(1, 0), (2, 0), (0, 2), (-2, 0), (0, -2)]
    assert oracle(radial_near, [(0, 0), (1, 0), (2, 0), (3, 0)]) == 3

    edges = [
        (triangle, []),
        (triangle, [(0, 0)]),
        (square, [(0, 0), (2, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]),
        (radial, [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (0, -1)]),
        (radial_near, [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1), (0, -1)]),
        ([(3, 0), (0, 3), (-3, 0), (0, -3)], [(0, 0), (1, 1), (-2, 2), (4, 0), (-4, 0)]),
    ]
    emit("2_edges", edges)

    rng = random.Random(2009)
    wide = []
    for count in (100000, 99999):
        polygon, sheep, expected = unambiguous_case(count, rng, 50000)
        for point in sheep[:3]:
            assert ray_cast(polygon, point)
        for point in sheep[-3:]:
            assert not ray_cast(polygon, point)
        wide.append((polygon, sheep, expected))
    emit_unambiguous("3_wide", wide)

    random_cases = []
    for _ in range(6):
        count = rng.randint(3, 900)
        polygon = star_polygon(count, rng, 2000, 30000)
        sheep = []
        for _ in range(600):
            angle = rng.uniform(0.0, 2.0 * math.pi)
            dist = rng.uniform(0.0, 34000.0)
            sheep.append((int(round(dist * math.cos(angle))), int(round(dist * math.sin(angle)))))
        sheep.append((0, 0))
        sheep.append(polygon[0])
        random_cases.append((polygon, sheep))
    emit("4_random", random_cases)

    io_cases = []
    for _ in range(12000):
        polygon = [(3, -3), (3, 3), (-3, 3), (-3, -3)]
        sheep = [(0, 0), (4, 4)]
        io_cases.append((polygon, sheep, 1))
    emit_unambiguous("5_io", io_cases)


if __name__ == "__main__":
    main()
