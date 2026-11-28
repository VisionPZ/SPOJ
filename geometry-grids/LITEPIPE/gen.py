#!/usr/bin/env python3
import math
import os
import random
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))


def height_at(points, x):
    for k in range(len(points) - 1):
        x0, y0 = points[k]
        x1, y1 = points[k + 1]
        if x0 <= x <= x1:
            if x1 == x0:
                return y0
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return points[-1][1]


def prefix_points(points, limit):
    result = []
    for point in points:
        if point[0] > limit:
            break
        result.append(point)
    if result and len(result) < len(points) and points[len(result)][0] > limit:
        result.append((limit, height_at(points, limit)))
    return result


def vertical_span(slope, pts):
    values = [y - slope * x for x, y in pts]
    return max(values) - min(values)


def feasible(limit, points):
    pts = prefix_points(points, limit)
    if len(pts) < 2:
        return True
    xs = [p[0] for p in pts]
    max_slope = 0.0
    for i in range(len(pts)):
        for j in range(i + 1, len(pts)):
            if xs[j] != xs[i]:
                max_slope = max(max_slope, abs((pts[j][1] - pts[i][1]) / (xs[j] - xs[i])))
    bound = max(4.0, max_slope * 2.0 + 2.0)
    low, high = -bound, bound
    for _ in range(60):
        first = low + (high - low) / 3.0
        second = high - (high - low) / 3.0
        if vertical_span(first, pts) < vertical_span(second, pts):
            high = second
        else:
            low = first
    best = min(vertical_span(low, pts), vertical_span(high, pts),
               vertical_span((low + high) / 2.0, pts))
    return best <= 1.0 + 1e-7


def oracle(points):
    low, high = points[0][0], points[-1][0]
    for _ in range(70):
        middle = (low + high) / 2.0
        if feasible(middle, points):
            low = middle
        else:
            high = middle
    return low


def exact_feasible(points, limit):
    limit_frac = Fraction(str(limit))
    pts = []
    for point in points:
        if Fraction(str(point[0])) > limit_frac:
            break
        pts.append((Fraction(str(point[0])), Fraction(str(point[1]))))
    if pts and len(pts) < len(points):
        left = pts[-1]
        right = (Fraction(str(points[len(pts)][0])),
                 Fraction(str(points[len(pts)][1])))
        weight = (limit_frac - left[0]) / (right[0] - left[0])
        pts.append((limit_frac, left[1] + weight * (right[1] - left[1])))
    if len(pts) < 2:
        return True
    low = Fraction(-10**9)
    high = Fraction(10**9)
    for i in range(len(pts)):
        for j in range(i + 1, len(pts)):
            dx = pts[j][0] - pts[i][0]
            if dx <= 0:
                continue
            centre = (pts[j][1] - pts[i][1]) / dx
            half = Fraction(1) / dx
            low = max(low, centre - half)
            high = min(high, centre + half)
            if low > high:
                return False
    return True


def brute_ray_cast(points, source_steps=1601, slope_steps=1201):
    first_x, first_y = points[0]
    last_x = points[-1][0]
    span = height_at(points, first_x) - 1.0 - first_y
    best = first_x
    min_s, max_s = -6.0, 6.0
    for source_index in range(source_steps + 1):
        source_y = first_y + span * source_index / source_steps
        for slope_index in range(slope_steps + 1):
            slope = min_s + (max_s - min_s) * slope_index / slope_steps
            reach = last_x
            wall_slope = (points[1][1] - points[0][1]) / (points[1][0] - first_x)
            blocked = False
            if abs(source_y - first_y) < 1e-9 and slope > wall_slope + 1e-12:
                reach = first_x
                blocked = True
            if abs(source_y - (first_y - 1.0)) < 1e-9 and slope < wall_slope - 1e-12:
                reach = first_x
                blocked = True
            if blocked:
                best = max(best, reach)
                continue
            for k in range(len(points) - 1):
                x0, y0 = points[k]
                x1, y1 = points[k + 1]
                hits = []
                for wall_y0, wall_y1 in ((y0, y1), (y0 - 1.0, y1 - 1.0)):
                    ray0 = source_y + slope * (x0 - first_x)
                    ray1 = source_y + slope * (x1 - first_x)
                    diff0 = ray0 - wall_y0
                    diff1 = ray1 - wall_y1
                    if diff0 == diff1:
                        continue
                    ratio = -diff0 / (diff1 - diff0)
                    if -1e-12 <= ratio <= 1.0 + 1e-12:
                        hit = x0 + ratio * (x1 - x0)
                        if x0 - 1e-9 <= hit <= x1 + 1e-9 and hit > first_x + 1e-9:
                            hits.append(hit)
                if hits:
                    reach = min(hits)
                    break
            best = max(best, reach)
    return best


def fmt(answer):
    return "{:.2f}".format(answer)


def render(cases):
    chunks = []
    for points in cases:
        chunks.append(str(len(points)))
        for x, y in points:
            chunks.append("{:.6f} {:.6f}".format(x, y))
    chunks.append("0")
    return "\n".join(chunks) + "\n"


def write_case(name, cases, answers=None):
    with open(os.path.join(HERE, "in", name + ".txt"), "w") as handle:
        handle.write(render(cases))
    if answers is None:
        answers = [oracle(points) for points in cases]
    with open(os.path.join(HERE, "out", name + ".out"), "w") as handle:
        handle.write("\n".join(fmt(answer) for answer in answers) + "\n")


def sample():
    return [(0.0, 1.0), (2.0, 2.0), (4.0, 1.0), (6.0, 4.0)]


def run_asserts():
    sample_answer = oracle(sample())
    assert abs(sample_answer - 14.0 / 3.0) < 1e-6, sample_answer
    assert exact_feasible(sample(), 14.0 / 3.0 - 1e-6)
    assert not exact_feasible(sample(), 14.0 / 3.0 + 1e-6)
    straight = [(0.0, 3.0), (10.0, 3.0), (20.0, 3.0)]
    assert abs(oracle(straight) - 20.0) < 1e-6, oracle(straight)
    tilted = [(0.0, 0.0), (10.0, 2.5), (30.0, 7.5)]
    assert abs(oracle(tilted) - 30.0) < 1e-6, oracle(tilted)
    single = [(7.25, 4.5)]
    assert abs(oracle(single) - 7.25) < 1e-9
    for trial in range(4):
        rng = random.Random(trial * 977 + 13)
        count = rng.randint(2, 5)
        xs = sorted(rng.sample(range(0, 60), count))
        points = [(float(x), round(rng.uniform(-3.0, 6.0), 3)) for x in xs]
        answer = oracle(points)
        cast = brute_ray_cast(points, 1201, 2401)
        assert cast <= answer + 1e-6, (points, answer, cast)
        assert answer - cast < 0.25, (points, answer, cast)


def main():
    run_asserts()

    write_case("1_sample", [sample()])

    edge_cases = [
        [(7.25, 4.5)],
        [(0.0, 0.0), (5.0, 0.0)],
        [(0.0, 2.0), (3.0, 2.0), (9.0, 2.0)],
        [(0.0, 0.0), (4.0, 4.0), (8.0, 0.0)],
        [(0.0, 4.0), (4.0, 0.0), (8.0, 4.0)],
        [(0.0, 1.0), (2.0, 2.0), (4.0, 1.0), (6.0, 4.0)],
        [(0.0, -2.0), (1.0, -2.0), (2.0, -2.0), (3.0, 8.0)],
        [(0.0, 0.0), (1.0, 0.001), (2.0, 0.0), (3.0, 0.001), (4.0, 0.0)],
        [(0.0, 10.0), (1.0, 11.0), (2.0, 10.0), (3.0, 11.0), (4.0, 10.0)],
        [(0.0, 0.0), (10.0, 0.5)],
    ]
    write_case("2_edges", edge_cases)

    wide_cases = []
    for seed in range(6):
        rng = random.Random(seed * 131 + 7)
        count = 200
        span = 1000.0 if seed % 2 == 0 else 50000.0
        base = float(seed * 37)
        points = []
        for k in range(count):
            x = base + span * k / (count - 1)
            y = base + rng.uniform(-8.0, 8.0) + 0.02 * x
            points.append((round(x, 4), round(y, 4)))
        wide_cases.append(points)
    write_case("3_wide", wide_cases)

    random_cases = []
    for seed in range(25):
        rng = random.Random(seed * 6151 + 101)
        count = rng.randint(20, 200)
        points = []
        x = float(rng.randint(-50, 50))
        y = rng.uniform(-10.0, 10.0)
        for k in range(count):
            points.append((round(x, 5), round(y, 5)))
            x += rng.uniform(0.05, 6.0)
            y += rng.uniform(-1.5, 1.5)
        random_cases.append(points)
    write_case("4_random", random_cases)

    io_cases = []
    for k in range(20000):
        base = float(k % 97) * 0.13
        io_cases.append([(base, 1.0 + (k % 7) * 0.1),
                         (base + 1.0, 2.0 + (k % 5) * 0.2)])
    io_answers = [case[-1][0] for case in io_cases]
    write_case("5_io", io_cases, io_answers)


if __name__ == "__main__":
    main()
