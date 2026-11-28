#!/usr/bin/env python3
import math
import random
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    cursor = 0
    cases = []
    count = int(tokens[cursor]); cursor += 1
    for _ in range(count):
        size = int(tokens[cursor]); cursor += 1
        points = []
        for _ in range(size):
            px = float(tokens[cursor]); cursor += 1
            py = float(tokens[cursor]); cursor += 1
            points.append((px, py))
        cases.append(points)
    assert cursor == len(tokens)
    return cases


def convex_hull(points):
    pts = sorted(set(points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

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


def oracle(points):
    hull = convex_hull(points)
    hx = np.array([p[0] for p in hull], dtype=np.float64)
    hy = np.array([p[1] for p in hull], dtype=np.float64)

    def max_squared(cx, cy):
        return float(np.max((hx - cx) ** 2 + (hy - cy) ** 2))

    def best_y(cx):
        lo, hi = -20000.0, 20000.0
        for _ in range(90):
            m1 = lo + (hi - lo) / 3.0
            m2 = hi - (hi - lo) / 3.0
            if max_squared(cx, m1) < max_squared(cx, m2):
                hi = m2
            else:
                lo = m1
        cy = (lo + hi) / 2.0
        return max_squared(cx, cy), cy

    lo, hi = -20000.0, 20000.0
    for _ in range(90):
        m1 = lo + (hi - lo) / 3.0
        m2 = hi - (hi - lo) / 3.0
        if best_y(m1)[0] < best_y(m2)[0]:
            hi = m2
        else:
            lo = m1
    cx = (lo + hi) / 2.0
    cy = best_y(cx)[1]
    return math.sqrt(max_squared(cx, cy)), cx, cy


def covers(circle, points):
    cx, cy, radius_squared = circle
    return all((px - cx) ** 2 + (py - cy) ** 2 <= radius_squared + 1e-6
               for px, py in points)


def circle_diameter(a, b):
    cx = (a[0] + b[0]) / 2.0
    cy = (a[1] + b[1]) / 2.0
    return cx, cy, ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) / 4.0


def circle_three(a, b, c):
    determinant = 2.0 * (a[0] * (b[1] - c[1]) +
                         b[0] * (c[1] - a[1]) +
                         c[0] * (a[1] - b[1]))
    if abs(determinant) < 1e-12:
        return None
    a2 = a[0] ** 2 + a[1] ** 2
    b2 = b[0] ** 2 + b[1] ** 2
    c2 = c[0] ** 2 + c[1] ** 2
    cx = (a2 * (b[1] - c[1]) + b2 * (c[1] - a[1]) + c2 * (a[1] - b[1])) / determinant
    cy = (a2 * (c[0] - b[0]) + b2 * (a[0] - c[0]) + c2 * (b[0] - a[0])) / determinant
    return cx, cy, (a[0] - cx) ** 2 + (a[1] - cy) ** 2


def brute(points):
    best = None
    for i in range(len(points)):
        for j in range(i + 1, len(points)):
            candidate = circle_diameter(points[i], points[j])
            if covers(candidate, points) and (best is None or candidate[2] < best[2]):
                best = candidate
    for i in range(len(points)):
        for j in range(i + 1, len(points)):
            for k in range(j + 1, len(points)):
                candidate = circle_three(points[i], points[j], points[k])
                if candidate is not None and covers(candidate, points) and (
                        best is None or candidate[2] < best[2]):
                    best = candidate
    return best


def formatted(value):
    text = f"{value:.2f}"
    return "0.00" if text == "-0.00" else text


def oracle_output(text):
    lines = []
    for points in parse(text):
        radius, cx, cy = oracle(points)
        lines.append(formatted(radius))
        lines.append(formatted(cx) + " " + formatted(cy))
    return "\n".join(lines) + "\n"


def write(name, cases):
    parts = [str(len(cases)) + "\n"]
    for points in cases:
        parts.append(str(len(points)) + "\n")
        parts.append("".join(f"{px:.6f} {py:.6f}\n" for px, py in points))
    input_text = "".join(parts)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_output(input_text))


SAMPLE = [[(8.0, 9.0), (4.0, 7.5), (1.0, 2.0),
           (5.1, 8.7), (9.0, 2.0), (4.5, 1.0)]]
sample_input = ("1\n6\n8.0 9.0\n4.0 7.5\n1.0 2.0\n"
                "5.1 8.7\n9.0 2.0\n4.5 1.0\n")
assert oracle_output(sample_input) == "5.00\n5.00 5.00\n"
assert abs(oracle(SAMPLE[0])[0] - 5.0) < 1e-6
assert abs(oracle([(0.0, 0.0), (10000.0, 10000.0),
                   (10000.0, -10000.0), (-10000.0, 10000.0)])[0]
           - 10000.0 * math.sqrt(2.0)) < 1e-6

random.seed(2002)
for _ in range(200):
    small = [(random.uniform(-50, 50), random.uniform(-50, 50))
             for _ in range(random.randint(2, 8))]
    exact = brute(small)
    approx = oracle(small)
    assert exact is not None
    assert abs(approx[0] - math.sqrt(exact[2])) < 1e-5
    assert abs(approx[1] - exact[0]) < 1e-5
    assert abs(approx[2] - exact[1]) < 1e-5


def build():
    edges = [
        [(-3.0, -4.0), (3.0, 4.0)],
        [(5.5, -2.5), (5.5, -2.5)],
        [(0.0, 0.0), (2.0, 0.0), (10.0, 0.0)],
        [(0.0, 0.0), (6.0, 0.0), (0.0, 8.0)],
        [(0.0, 0.0), (4.0, 0.0), (2.0, 3.464101615)],
        [(-1.0, -1.0), (-1.0, 1.0), (1.0, -1.0), (1.0, 1.0)],
        [(123.45, -67.89), (123.4501, -67.8901), (123.4499, -67.8899)],
        [(10000.0, 10000.0), (10000.0, -10000.0),
         (-10000.0, 10000.0), (-10000.0, -10000.0)],
        [(107.0, -200.0), (93.0, -200.0), (100.0, -193.0), (100.0, -207.0)],
        [(0.0, 0.0), (0.1, 0.0), (0.0, 0.1), (9999.0, 9999.0)],
    ]
    write("2_edges", edges)

    wide = [
        [(random.uniform(-10000, 10000), random.uniform(-10000, 10000))
         for _ in range(100000)],
        [(random.uniform(1000, 1000.01), random.uniform(-2000, -1999.99))
         for _ in range(100000)],
    ]
    write("3_wide", wide)

    random_cases = []
    for case_index in range(20):
        size = 20000
        if case_index % 4 == 0:
            points = [(random.uniform(-10000, 10000), random.uniform(-10000, 10000))
                      for _ in range(size)]
        elif case_index % 4 == 1:
            angle = random.uniform(0, 6.283185307179586)
            radius = random.uniform(100, 9000)
            center_x = random.uniform(-5000, 5000)
            center_y = random.uniform(-5000, 5000)
            points = [(center_x + radius * math.cos(angle * t / size),
                       center_y + radius * math.sin(angle * t / size))
                      for t in range(size)]
        elif case_index % 4 == 2:
            points = [(random.gauss(1000, 30), random.gauss(-2000, 30))
                      for _ in range(size)]
        else:
            points = [(random.choice([-10000.0, 10000.0]) + random.uniform(-1, 1),
                       random.uniform(-10000, 10000)) for _ in range(size)]
        random_cases.append(points)
    write("4_random", random_cases)

    io_cases = []
    for case_index in range(20):
        size = 100000
        if case_index % 2 == 0:
            io_cases.append([(random.uniform(-10000, 10000), random.uniform(-10000, 10000))
                             for _ in range(size)])
        else:
            io_cases.append([(random.gauss(0, 3000), random.gauss(0, 3000))
                             for _ in range(size)])
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
