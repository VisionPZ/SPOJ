import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)



def round_two(value):
    """Round half up to two decimals, the rule the statement gives."""
    scaled = value * 100.0
    negative = scaled < 0.0
    rounded = int((-scaled if negative else scaled) + 0.5)
    if rounded == 0:
        return "0.00"
    text = "%03d" % rounded
    return ("-" if negative else "") + text[:-2] + "." + text[-2:]


assert round_two(-0.004) == "0.00"


def centroid(points):
    """Triangle fan from the first vertex, area weighted."""
    origin = points[0]
    areaSum = 0.0
    weightedX = 0.0
    weightedY = 0.0
    for index in range(1, len(points) - 1):
        second, third = points[index], points[index + 1]
        area = 0.5 * ((second[0] - origin[0]) * (third[1] - origin[1]) -
                      (second[1] - origin[1]) * (third[0] - origin[0]))
        areaSum += area
        weightedX += area * (origin[0] + second[0] + third[0]) / 3.0
        weightedY += area * (origin[1] + second[1] + third[1]) / 3.0
    if areaSum == 0.0:
        return "0.00 0.00"
    return round_two(weightedX / areaSum) + " " + round_two(weightedY / areaSum)


def oracle(points):
    return centroid(points) + "\n"


def write(name, cases):
    body = "%d\n" % len(cases)
    for points in cases:
        body += "%d\n" % len(points)
        body += "".join("%d %d\n" % p for p in points)
    open("in/%s.txt" % name, "w").write(body)
    open("out/%s.out" % name, "w").write("".join(oracle(p) for p in cases))


sample = [[(5, 0), (0, 5), (-5, 0), (0, -5)], [(1, 1), (11, 1), (11, 11), (1, 11)]]
write("1_sample", sample)

assert "".join(oracle(p) for p in sample) == "0.00 0.00\n6.00 6.00\n"

edges = [[(0, 0), (3, 0), (0, 4)], [(0, 0), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0)],
         [(10000, -10000), (10000, 10000), (-10000, 10000)],
         [(-20000, 0), (0, -20000), (20000, 0), (0, 20000)],
         [(0, 0), (1, 0), (2, 1), (1, 2), (0, 1)],
         [(7, 7), (7, -7), (-7, -7), (-7, 7), (0, 0)],
         [(0, 0), (5, 0), (5, 5), (0, 5)], [(0, 0), (1, 1), (2, 0), (1, -1)],
         [(3, 3), (3, -3), (-3, -3), (-3, 3), (-3, 0), (0, 3)]]
write("2_edges", edges)

rng = random.Random(4)
wide = [[(rng.randint(-20000, 20000), rng.randint(-20000, 20000))
         for _ in range(100000)] for _ in range(4)]
write("3_wide", wide)


def starPolygon(rng, pointCount):
    """A simple polygon: walk around a circle with jittered radii."""
    points = []
    for index in range(pointCount):
        angle = 6.283185307179586 * index / pointCount
        radius = 1000 + rng.randint(0, 19000)
        x = int(round(radius * __import__("math").cos(angle)))
        y = int(round(radius * __import__("math").sin(angle)))
        points.append((max(-20000, min(20000, x)), max(-20000, min(20000, y))))
    return points


cases = [starPolygon(random.Random(9), 200000)] + [starPolygon(rng, 5000) for _ in range(49)]
write("4_random", cases)

write("5_io", [starPolygon(random.Random(3000 + i), 2000) for i in range(500)])
