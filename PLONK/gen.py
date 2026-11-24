#!/usr/bin/env python3
import random
from bisect import bisect_left, bisect_right
from itertools import accumulate
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """1
7
1 3
3 2
3 5
6 9
10 1
12 4
5 7
"""

SAMPLE_OUTPUT = "39\n"


def oracle_brute(cases):
    answers = []
    for points in cases:
        best = None
        for meet_x, meet_y in points:
            total = 0
            for point_x, point_y in points:
                total += abs(point_x - meet_x) + abs(point_y - meet_y)
            if best is None or total < best:
                best = total
        answers.append(str(best))
    return answers


def oracle_fast(cases):
    answers = []
    for points in cases:
        xs = sorted(point[0] for point in points)
        ys = sorted(point[1] for point in points)
        sum_x = [0] + list(accumulate(xs))
        sum_y = [0] + list(accumulate(ys))
        best = None
        for meet_x, meet_y in points:
            left_x = bisect_left(xs, meet_x)
            right_x = bisect_right(xs, meet_x)
            cost_x = (meet_x * left_x - sum_x[left_x]
                      + sum_x[-1] - sum_x[right_x]
                      - meet_x * (len(xs) - right_x))
            left_y = bisect_left(ys, meet_y)
            right_y = bisect_right(ys, meet_y)
            cost_y = (meet_y * left_y - sum_y[left_y]
                      + sum_y[-1] - sum_y[right_y]
                      - meet_y * (len(ys) - right_y))
            total = cost_x + cost_y
            if best is None or total < best:
                best = total
        answers.append(str(best))
    return answers


def format_answer(answers):
    return "\n".join(answers) + "\n"


def write(name, cases, answers):
    input_text = str(len(cases)) + "\n"
    for points in cases:
        input_text += str(len(points)) + "\n"
        for point_x, point_y in points:
            input_text += f"{point_x} {point_y}\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(format_answer(answers))


assert oracle_brute([[(1, 3), (3, 2), (3, 5), (6, 9), (10, 1), (12, 4), (5, 7)]]) == ["39"]
assert oracle_brute([[(0, 0), (100000, 100000)]]) == ["200000"]
assert oracle_brute([[(5, 0), (5, 100000), (5, 50000)]]) == ["100000"]
random.seed(7)
probe_cases = [[(random.randint(0, 30), random.randint(0, 30))
                for _ in range(random.randint(1, 12))] for _ in range(40)]
assert oracle_brute(probe_cases) == oracle_fast(probe_cases)


def build():
    edges = [
        [(0, 0)],
        [(0, 0), (100000, 100000)],
        [(7, 9), (7, 9), (7, 9)],
        [(5, 0), (5, 100000), (5, 50000)],
        [(0, 0), (100000, 0)],
        [(0, 50000), (100000, 50000), (50000, 0), (50000, 100000)],
        [(0, 0), (0, 0), (100000, 100000), (100000, 100000)],
    ]
    write("2_edges", edges, oracle_brute(edges))

    random.seed(1207)
    wide = [
        [(0, 0) for _ in range(10000)],
        [(i % 100001, 100000 - (i % 100001)) for i in range(10000)],
        [(random.randint(0, 100000), random.randint(0, 100000)) for _ in range(10000)],
    ]
    write("3_wide", wide, oracle_fast(wide))

    random.seed(99)
    mixed = []
    for _ in range(60):
        size = random.randint(1, 400)
        mixed.append([(random.randint(0, 100000), random.randint(0, 100000))
                      for _ in range(size)])
    write("4_random", mixed, oracle_brute(mixed))

    random.seed(2026)
    io_cases = []
    for _ in range(20000):
        io_cases.append([(random.randint(0, 100000), random.randint(0, 100000))
                         for _ in range(2)])
    write("5_io", io_cases, oracle_fast(io_cases))


def worked_example():
    points = [(1, 3), (3, 2), (3, 5), (6, 9), (10, 1), (12, 4), (5, 7)]
    xs = sorted(point[0] for point in points)
    ys = sorted(point[1] for point in points)
    sum_x = [0] + list(accumulate(xs))
    sum_y = [0] + list(accumulate(ys))
    print("| Friend | x cost | y cost | total |")
    print("| --- | --- | --- | --- |")
    for point_x, point_y in points:
        left_x = bisect_left(xs, point_x)
        right_x = bisect_right(xs, point_x)
        cost_x = (point_x * left_x - sum_x[left_x] + sum_x[-1] - sum_x[right_x]
                  - point_x * (len(xs) - right_x))
        left_y = bisect_left(ys, point_y)
        right_y = bisect_right(ys, point_y)
        cost_y = (point_y * left_y - sum_y[left_y] + sum_y[-1] - sum_y[right_y]
                  - point_y * (len(ys) - right_y))
        print(f"| ({point_x}, {point_y}) | {cost_x} | {cost_y} | {cost_x + cost_y} |")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
if __name__ == "__main__":
    worked_example()
