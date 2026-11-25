#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TWO_PI = 2.0 * math.pi


def max_depth_at_angle(circles, theta):
    normal_x = math.cos(theta)
    normal_y = math.sin(theta)
    events = []
    for center_x, center_y, radius in circles:
        projection = center_x * normal_x + center_y * normal_y
        events.append((projection - radius, 1))
        events.append((projection + radius, -1))
    events.sort()
    depth = 0
    best = 0
    for _, delta in events:
        depth += delta
        if depth > best:
            best = depth
    return best


def oracle_circles(circles):
    if not circles:
        return 0
    critical = set()
    for first_index in range(len(circles)):
        for second_index in range(first_index + 1, len(circles)):
            first_x, first_y, first_radius = circles[first_index]
            second_x, second_y, second_radius = circles[second_index]
            delta_x = first_x - second_x
            delta_y = first_y - second_y
            distance = math.hypot(delta_x, delta_y)
            if distance < 1e-12:
                continue
            direction = math.atan2(delta_y, delta_x)
            for first_sign in (-1, 1):
                for second_sign in (-1, 1):
                    ratio = (second_sign * second_radius - first_sign * first_radius) / distance
                    if -1.0 <= ratio <= 1.0:
                        shift = math.acos(ratio)
                        critical.add((direction + shift) % TWO_PI)
                        critical.add((direction - shift) % TWO_PI)
    critical.add(0.0)
    angles = sorted(critical)
    best = 0
    for angle_index in range(len(angles)):
        start = angles[angle_index]
        finish = angles[angle_index + 1] if angle_index + 1 < len(angles) else angles[0] + TWO_PI
        depth = max_depth_at_angle(circles, (start + finish) / 2.0)
        if depth > best:
            best = depth
    return best


def oracle(text):
    tokens = text.split()
    cursor = 0
    event_count = int(tokens[cursor])
    cursor += 1
    active = {}
    next_index = 0
    answers = []
    for _ in range(event_count):
        kind = int(tokens[cursor])
        cursor += 1
        if kind == 1:
            center_x = float(tokens[cursor])
            center_y = float(tokens[cursor + 1])
            radius = float(tokens[cursor + 2])
            cursor += 3
            next_index += 1
            active[next_index] = (center_x, center_y, radius)
        elif kind == 2:
            circle_index = int(tokens[cursor])
            cursor += 1
            del active[circle_index]
        else:
            answers.append(str(oracle_circles(list(active.values()))))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """9
1 3.00 0.00 1.00
1 -2.00 0.00 1.00
3
1 2.00 3.00 1.50
3
1 2.00 -4.00 1.00
3
2 3
3
"""
SAMPLE_OUT = """2
2
3
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n1 0 0 1\n3\n") == "1\n"
assert oracle("5\n1 0 0 1\n1 4 0 1\n3\n2 1\n3\n") == "2\n1\n"
assert oracle("6\n1 0 0 1\n1 0 0 2\n1 0 0 3\n3\n2 1\n3\n") == "3\n2\n"
assert oracle("6\n1 0 0 1\n1 5 0 1\n1 10 0 1\n3\n2 2\n3\n") == "3\n2\n"
assert max_depth_at_angle([(0.0, 0.0, 1.0)], 0.0) == 1


def event(kind, *values):
    return str(kind) + (" " + " ".join(map(str, values)) if values else "") + "\n"


def circle(circle_index):
    center_x, center_y, radius = circle_index
    return (f"{center_x / 100:.2f}", f"{center_y / 100:.2f}", f"{radius / 100:.2f}")


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = "".join([
        event(3),
        event(1, *circle((0, 0, 100))),
        event(3),
        event(2, 1),
        event(3),
        event(1, *circle((0, 0, 100))),
        event(1, *circle((500, 0, 100))),
        event(3),
        event(1, *circle((0, 0, 300))),
        event(1, *circle((0, 0, 200))),
        event(3),
        event(1, *circle((0, 0, 100))),
        event(1, *circle((1000, 0, 100))),
        event(1, *circle((2000, 0, 100))),
        event(3),
    ])
    write("2_edges", edges)
    rng = random.Random(20261126)
    wide = []
    placed = []
    for _ in range(100):
        for _attempt in range(200):
            center_x = rng.randint(-20000, 20000)
            center_y = rng.randint(-20000, 20000)
            radius = rng.randint(100, 2000)
            if all(math.hypot(center_x - other_x, center_y - other_y) > radius + other_r + 500
                   for other_x, other_y, other_r in placed):
                placed.append((center_x, center_y, radius))
                wide.append(event(1, *circle((center_x, center_y, radius))))
                break
    wide.append(event(3))
    write("3_wide", str(len(wide)) + "\n" + "".join(wide))
    random_events = []
    active_positions = {}
    next_index = 0
    for _ in range(120):
        if rng.random() < 0.65 and next_index < 12:
            while True:
                center_x = rng.randint(-1000, 1000)
                center_y = rng.randint(-1000, 1000)
                radius = rng.randint(20, 150)
                if all(math.hypot(center_x - other[0], center_y - other[1]) > radius + other[2] + 20
                       for other in active_positions.values()):
                    break
            next_index += 1
            active_positions[next_index] = (center_x, center_y, radius)
            random_events.append(event(1, *circle((center_x, center_y, radius))))
        elif active_positions:
            removed = rng.choice(list(active_positions))
            del active_positions[removed]
            random_events.append(event(2, removed))
        else:
            random_events.append(event(3))
        if rng.random() < 0.3:
            random_events.append(event(3))
    write("4_random", str(len(random_events)) + "\n" + "".join(random_events))
    io_events = []
    io_circles = {}
    io_next = 0
    for step in range(400):
        if io_next < 40 and rng.random() < 0.7:
            while True:
                center_x = rng.randint(-5000, 5000)
                center_y = rng.randint(-5000, 5000)
                radius = rng.randint(50, 400)
                if all(math.hypot(center_x - other[0], center_y - other[1]) > radius + other[2] + 100
                       for other in io_circles.values()):
                    break
            io_next += 1
            io_circles[io_next] = (center_x, center_y, radius)
            io_events.append(event(1, *circle((center_x, center_y, radius))))
        elif io_circles and rng.random() < 0.3:
            removed = rng.choice(list(io_circles))
            del io_circles[removed]
            io_events.append(event(2, removed))
        else:
            io_events.append(event(3))
    write("5_io", str(len(io_events)) + "\n" + "".join(io_events))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
