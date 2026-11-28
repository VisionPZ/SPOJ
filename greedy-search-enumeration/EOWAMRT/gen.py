#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EPS = 1e-9


def oracle(text):
    values = text.split()
    pos = 0
    answers = []
    while pos + 2 < len(values):
        robot_count = int(values[pos])
        period = int(values[pos + 1])
        radius = int(values[pos + 2])
        pos += 3
        if robot_count == 0 and period == 0 and radius == 0:
            break
        routes = []
        for _ in range(robot_count):
            nickname = values[pos]
            pos += 1
            segments = []
            previous_time = 0
            current_x = 0
            current_y = 0
            while True:
                stamp = int(values[pos])
                first = int(values[pos + 1])
                second = int(values[pos + 2])
                pos += 3
                if stamp == 0:
                    current_x, current_y = first, second
                else:
                    segments.append((previous_time, stamp, current_x, current_y, first, second))
                    current_x += first * (stamp - previous_time)
                    current_y += second * (stamp - previous_time)
                previous_time = stamp
                if stamp == period:
                    break
            routes.append((nickname, segments))

        def state(route, time_value):
            for start, end, pos_x, pos_y, vel_x, vel_y in route[1]:
                if start - EPS <= time_value <= end + EPS:
                    return (pos_x + vel_x * (time_value - start),
                            pos_y + vel_y * (time_value - start), vel_x, vel_y)
            return (0.0, 0.0, 0.0, 0.0)

        def bisect_cross(function, low, high):
            low_positive = function(low) > 0
            for _ in range(70):
                middle = (low + high) / 2.0
                if (function(middle) > 0) == low_positive:
                    low = middle
                else:
                    high = middle
            return (low + high) / 2.0

        def contacts(first_route, second_route):
            stamps = {0, period}
            for _, segments in (first_route, second_route):
                for start, end, _, _, _, _ in segments:
                    stamps.add(start)
                    stamps.add(end)
            ordered = sorted(stamps)
            found = []
            for left, right in zip(ordered, ordered[1:]):
                length = right - left
                if length <= EPS:
                    continue
                ax, ay, avx, avy = state(first_route, left)
                bx, by, bvx, bvy = state(second_route, left)
                rel_x, rel_y = ax - bx, ay - by
                vx, vy = avx - bvx, avy - bvy
                curvature = vx * vx + vy * vy

                def function(local_time):
                    return ((rel_x + vx * local_time) ** 2 +
                            (rel_y + vy * local_time) ** 2 - radius * radius)

                value_left = function(0.0)
                value_right = function(length)
                if value_left <= EPS and value_right <= EPS:
                    found.append((left, right))
                    continue
                trials = [0.0, length]
                if curvature > 0:
                    critical = -(rel_x * vx + rel_y * vy) / curvature
                    if 0 < critical < length:
                        trials.append(critical)
                minimum_time = min(trials, key=function)
                if function(minimum_time) > EPS:
                    continue
                crossings = []
                if value_left <= EPS:
                    crossings.append(0.0)
                else:
                    crossings.append(bisect_cross(function, 0.0, minimum_time))
                if value_right <= EPS:
                    crossings.append(length)
                else:
                    crossings.append(bisect_cross(function, minimum_time, length))
                found.append((left + crossings[0], left + crossings[1]))
            merged = []
            for interval in found:
                if merged and interval[0] <= merged[-1][1] + EPS:
                    merged[-1] = (merged[-1][0], max(merged[-1][1], interval[1]))
                else:
                    merged.append(interval)
            return merged

        contact_table = [[[] for _ in range(robot_count)] for _ in range(robot_count)]
        for first in range(robot_count):
            for second in range(first + 1, robot_count):
                shared = contacts(routes[first], routes[second])
                contact_table[first][second] = shared
                contact_table[second][first] = shared

        known = [float("inf")] * robot_count
        known[0] = 0.0
        for _ in range(robot_count):
            changed = False
            for sender in range(robot_count):
                if known[sender] > period:
                    continue
                for receiver in range(robot_count):
                    for start, end in contact_table[sender][receiver]:
                        if end + EPS >= known[sender]:
                            learn = max(start, known[sender])
                            if learn < known[receiver] - EPS:
                                known[receiver] = learn
                                changed = True
                            break
            if not changed:
                break
        answers.extend(sorted(routes[index][0] for index in range(robot_count)
                              if known[index] <= period + EPS))
    return "".join(name + "\n" for name in answers)


SAMPLE = """3 5 10
red
0 0 0
5 0 0
green
0 5 5
5 6 1
blue
0 40 5
5 0 0
3 10 5
atom
0 47 32
5 -10 -7
10 1 0
pluto
0 0 0
7 0 0
10 3 3
gesicht
0 25 7
5 -7 -2
10 -1 10
4 100 7
impulse
0 -500 0
100 10 1
freedom
0 -491 0
100 9 2
destiny
0 -472 0
100 7 4
strike
0 -482 0
100 8 3
0 0 0
"""
SAMPLE_OUT = """blue
green
red
atom
gesicht
pluto
freedom
impulse
strike
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 5 3\nsolo\n0 0 0\n5 0 0\n0 0 0\n") == "solo\n"
assert oracle("2 5 3\nabc\n0 0 0\n5 0 0\nxyz\n0 40 0\n5 0 0\n0 0 0\n") == "abc\n"
assert oracle("2 5 3\nabc\n0 0 0\n5 0 0\nxyz\n0 2 0\n5 0 0\n0 0 0\n") == "abc\nxyz\n"


def render(robots, period, radius):
    lines = [f"{len(robots)} {period} {radius}\n"]
    for nickname, segments in robots:
        lines.append(nickname + "\n")
        if segments:
            lines.append(f"0 {segments[0][2]} {segments[0][3]}\n")
            for start, end, pos_x, pos_y, vel_x, vel_y in segments:
                lines.append(f"{end} {vel_x} {vel_y}\n")
        else:
            lines.append("0 0 0\n")
    return "".join(lines)


def stationary(name, x, y, period):
    return (name, [(0, period, x, y, 0, 0)])


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = ""
    edges += render([stationary("solo", 0, 0, 5)], 5, 3)
    edges += render([stationary("abc", 0, 0, 5), stationary("xyz", 40, 0, 5)], 5, 3)
    edges += render([stationary("abc", 0, 0, 5), stationary("xyz", 2, 0, 5)], 5, 3)
    edges += render([stationary("one", 0, 0, 5), stationary("two", 2, 0, 5),
                     stationary("three", 4, 0, 5)], 5, 3)
    write("2_edges", edges + "0 0 0\n")
    write("3_wide", render([stationary(f"robot{index}", index * 4, 0, 20)
                            for index in range(10)], 20, 3) + "0 0 0\n")
    rng = random.Random(20261120)
    random_text = ""
    for _ in range(5):
        robots = []
        used = set()
        for robot_index in range(4):
            nickname = f"bot{robot_index}"
            used.add(nickname)
            start_x = rng.randint(-30, 30)
            start_y = rng.randint(-30, 30)
            velocity = (rng.randint(-3, 3), rng.randint(-3, 3))
            segments = [(0, 10, start_x, start_y, velocity[0], velocity[1])]
            robots.append((nickname, segments))
        for first_index in range(4):
            for second_index in range(first_index + 1, 4):
                first = robots[first_index][1][0]
                second = robots[second_index][1][0]
                distance = math.hypot(first[2] - second[2], first[3] - second[3])
                if abs(distance - 5) < 1e-6:
                    robots[second_index] = (robots[second_index][0],
                                            [(0, 10, second[2] + 7, second[3] + 7,
                                              second[4], second[5])])
        random_text += render(robots, 10, 5)
    write("4_random", random_text + "0 0 0\n")
    io_text = ""
    for case_index in range(20):
        robots = []
        for robot_index in range(8):
            nickname = f"r{case_index}_{robot_index}"
            robots.append(stationary(nickname, robot_index * 2, 0, 10))
        io_text += render(robots, 10, 3)
    write("5_io", io_text + "0 0 0\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
