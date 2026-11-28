#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def cross(o, a, b):
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])


def hull(points):
    pts = sorted(set(points))
    if len(pts) <= 1:
        return pts
    lower = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def triangle2(poly, i, j, k):
    h = len(poly)
    a = poly[i % h]
    b = poly[j % h]
    c = poly[k % h]
    return abs(cross(a, b, c))


def diagonal_area2(points):
    poly = hull(points)
    size = len(poly)
    if size < 3:
        return 0
    if size == 3:
        return triangle2(poly, 0, 1, 2)
    best = 0
    for i in range(size):
        low = i + 1
        high = i + 2
        for j in range(i + 2, i + size - 1):
            while low + 1 < j and triangle2(poly, i, j, low + 1) >= triangle2(poly, i, j, low):
                low += 1
            if high <= j:
                high = j + 1
            while high < i + size - 1 and triangle2(poly, i, j, high + 1) >= triangle2(poly, i, j, high):
                high += 1
            left = triangle2(poly, i, j, low) if low < j else 0
            right = triangle2(poly, i, j, high) if high <= i + size - 1 else 0
            best = max(best, left + right)
    return best


def brute_area2(points):
    poly = hull(points)
    size = len(poly)
    if size < 3:
        return 0
    if size == 3:
        return triangle2(poly, 0, 1, 2)
    best = 0
    for i in range(size):
        for j in range(i + 1, size):
            for k in range(j + 1, size):
                for l in range(k + 1, size):
                    a = poly[i]
                    b = poly[j]
                    c = poly[k]
                    d = poly[l]
                    value = (c[0] - a[0]) * (d[1] - b[1]) - (c[1] - a[1]) * (d[0] - b[0])
                    best = max(best, abs(value))
    return best


def format_area(area2):
    return "%d.%d" % (area2 // 2, 0 if area2 % 2 == 0 else 5)


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        size = int(tokens[cursor])
        cursor += 1
        points = []
        for _ in range(size):
            px = int(tokens[cursor])
            py = int(tokens[cursor + 1])
            cursor += 2
            points.append((px, py))
        answers.append(format_area(diagonal_area2(points)))
    return "\n".join(answers) + "\n"


def write(name, cases):
    lines = [str(len(cases)), ""]
    for points in cases:
        lines.append(str(len(points)))
        for px, py in points:
            lines.append("%d %d" % (px, py))
        lines.append("")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


sample = [
    [(0, 0), (1, 0), (1, 1), (0, 1)],
    [(0, 0), (0, 1), (1, 1), (1, 0)],
]
assert oracle("2\n\n4\n0 0\n1 0\n1 1\n0 1\n\n4\n0 0\n0 1\n1 1\n1 0\n\n") == "1.0\n1.0\n"
assert oracle("1\n\n4\n-20000 -20000\n20000 -20000\n20000 20000\n-20000 20000\n\n") == "1600000000.0\n"
assert oracle("1\n\n4\n0 2\n2 -2\n-2 -2\n-1 -1\n\n") == "8.0\n"
assert oracle("1\n\n4\n0 0\n4 0\n0 3\n1 1\n\n") == "6.0\n"
assert oracle("1\n\n4\n0 0\n1 0\n2 0\n3 0\n\n") == "0.0\n"

random.seed(20261124)
for _ in range(300):
    pts = [(random.randint(-12, 12), random.randint(-12, 12)) for _ in range(random.randint(4, 9))]
    assert diagonal_area2(pts) == brute_area2(pts)


def circle_points(count):
    result = []
    for i in range(count):
        angle = 2.0 * math.pi * i / count
        result.append((int(round(19999 * math.cos(angle))), int(round(19999 * math.sin(angle)))))
    return result


def build():
    edges = [
        [(0, 0), (1, 0), (1, 1), (0, 1)],
        [(0, 2), (2, -2), (-2, -2), (-1, -1)],
        [(0, 0), (4, 0), (0, 3), (1, 1)],
        [(0, 0), (1, 0), (2, 0), (3, 0)],
        [(7, 7), (7, 7), (7, 7), (7, 7)],
        [(-20000, -20000), (20000, -20000), (20000, 20000), (-20000, 20000)],
        [(0, 0), (10, 0), (10, 10), (0, 10), (5, 5), (2, 3), (8, 7)],
        [(-3, -4), (3, -4), (0, 5), (0, 0), (1, 1), (-1, 1)],
        [(100, 100), (-100, 100), (-100, -100), (100, -100), (0, 0)],
        [(0, 0), (20000, 1), (19999, 20000), (1, 19999)],
    ]
    write("2_edges", edges)

    wide = [circle_points(2000)]
    for _ in range(79):
        wide.append([(random.randint(-20000, 20000), random.randint(-20000, 20000))
                     for _ in range(2000)])
    write("3_wide", wide)

    rand_cases = []
    for _ in range(20):
        size = random.randint(4, 300)
        rand_cases.append([(random.randint(-20000, 20000), random.randint(-20000, 20000))
                           for _ in range(size)])
    write("4_random", rand_cases)

    io_cases = []
    for case_index in range(80):
        base = [(0, 0), (19999, 0), (0, 19999), (5, 5)]
        points = []
        for i in range(2000):
            points.append(base[i % 4] if i % 3 else (case_index + 1, i % 19999))
        io_cases.append(points)
    write("5_io", io_cases)


def worked_example():
    points = [(0, 0), (6, 0), (6, 4), (0, 4), (2, 2), (3, 1)]
    print("points", points)
    print("hull", hull(points))
    area2 = diagonal_area2(points)
    print("doubled area", area2)
    print("answer", format_area(area2))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", sample)
build()
worked_example()
