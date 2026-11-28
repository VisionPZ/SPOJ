#!/usr/bin/env python3
import heapq
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EPS = 1e-7

SAMPLE_IN = """3

0 0 5
4 0 3
3.0 4.0
1.878679656440357 -2.121320343559643

0 0 5
4 0 3
4.0 3.0
4.0 -3.0

0 0 4
10 0 4
4.0 0.0
6.0 0.0
"""

SAMPLE_OUT = """8.4875540166
6.4350110879
-1
"""


def fmt(value):
    return f"{value:.10f}"


def arc(cx, cy, radius, first, second):
    delta_first_x = first[0] - cx
    delta_first_y = first[1] - cy
    delta_second_x = second[0] - cx
    delta_second_y = second[1] - cy
    cross = delta_first_x * delta_second_y - delta_first_y * delta_second_x
    dot = delta_first_x * delta_second_x + delta_first_y * delta_second_y
    return radius * math.atan2(abs(cross), dot)


def parse(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(count):
        first_circle = (int(tokens[cursor]), int(tokens[cursor + 1]), int(tokens[cursor + 2]))
        cursor += 3
        second_circle = (int(tokens[cursor]), int(tokens[cursor + 1]), int(tokens[cursor + 2]))
        cursor += 3
        home = (float(tokens[cursor]), float(tokens[cursor + 1]))
        cursor += 2
        school = (float(tokens[cursor]), float(tokens[cursor + 1]))
        cursor += 2
        cases.append((first_circle, second_circle, home, school))
    return cases


def intersections(first_circle, second_circle):
    cx1, cy1, radius1 = first_circle
    cx2, cy2, radius2 = second_circle
    first_radius = float(radius1)
    second_radius = float(radius2)
    delta_x = cx2 - cx1
    delta_y = cy2 - cy1
    distance = math.hypot(delta_x, delta_y)
    if distance < EPS:
        return []
    if distance > first_radius + second_radius + EPS:
        return []
    if distance < abs(first_radius - second_radius) - EPS:
        return []
    unit_x = delta_x / distance
    unit_y = delta_y / distance
    along = (distance * distance + first_radius * first_radius -
             second_radius * second_radius) / (2.0 * distance)
    height_squared = first_radius * first_radius - along * along
    if height_squared < -EPS:
        return []
    height = math.sqrt(max(0.0, height_squared))
    base_x = cx1 + along * unit_x
    base_y = cy1 + along * unit_y
    result = [(base_x - height * unit_y, base_y + height * unit_x)]
    if height >= EPS:
        result.append((base_x + height * unit_y, base_y - height * unit_x))
    return result


def solve_case(first_circle, second_circle, home, school):
    cx1, cy1, radius1 = first_circle
    cx2, cy2, radius2 = second_circle
    first_radius = float(radius1)
    second_radius = float(radius2)
    distance = math.hypot(cx2 - cx1, cy2 - cy1)
    coincident = distance < EPS and abs(first_radius - second_radius) < EPS
    if coincident:
        return fmt(arc(cx1, cy1, first_radius, home, school))

    def circle_of(point):
        error1 = abs(math.hypot(point[0] - cx1, point[1] - cy1) - first_radius)
        error2 = abs(math.hypot(point[0] - cx2, point[1] - cy2) - second_radius)
        return 1 if error1 <= error2 else 2

    home_circle = circle_of(home)
    school_circle = circle_of(school)
    crossing_points = intersections(first_circle, second_circle)
    nodes = [home, school] + crossing_points
    on_first = [home_circle == 1, school_circle == 1] + [True] * len(crossing_points)
    on_second = [home_circle == 2, school_circle == 2] + [True] * len(crossing_points)
    node_count = len(nodes)

    adjacency = [dict() for _ in range(node_count)]
    for circle_index, (cx, cy, radius, on_circle) in enumerate(
            [(cx1, cy1, first_radius, on_first), (cx2, cy2, second_radius, on_second)]):
        ports = [index for index in range(node_count) if on_circle[index]]
        if len(ports) < 2:
            continue
        ports.sort(key=lambda index: math.atan2(nodes[index][1] - cy, nodes[index][0] - cx) % (2 * math.pi))
        for position, port in enumerate(ports):
            following = ports[(position + 1) % len(ports)]
            weight = arc(cx, cy, radius, nodes[port], nodes[following])
            adjacency[port][following] = min(adjacency[port].get(following, math.inf), weight)
            adjacency[following][port] = min(adjacency[following].get(port, math.inf), weight)

    best = [math.inf]

    def walk(current, visited, total):
        if current == 1:
            if total < best[0]:
                best[0] = total
            return
        for following, weight in adjacency[current].items():
            if following not in visited:
                walk(following, visited | {following}, total + weight)

    walk(0, {0}, 0.0)
    if best[0] == math.inf:
        return "-1"
    return fmt(best[0])


def oracle(text):
    lines = [solve_case(*case) for case in parse(text)]
    return "\n".join(lines) + "\n"


def brute_dense(first_circle, second_circle, home, school, steps=4000):
    cx1, cy1, radius1 = first_circle
    cx2, cy2, radius2 = second_circle

    def ring(cx, cy, radius):
        if radius == 0:
            return [(cx, cy)]
        return [(cx + radius * math.cos(2 * math.pi * k / steps),
                 cy + radius * math.sin(2 * math.pi * k / steps)) for k in range(steps)]

    points1 = ring(cx1, cy1, radius1)
    points2 = ring(cx2, cy2, radius2)
    points = points1 + points2
    offset = len(points1)
    total = len(points)
    neighbours = [[] for _ in range(total)]
    for start, count, radius in [(0, len(points1), radius1), (offset, len(points2), radius2)]:
        if radius <= 0:
            continue
        step_weight = radius * 2 * math.pi / steps
        for k in range(count):
            following = start + (k + 1) % count
            neighbours[start + k].append((following, step_weight))
            neighbours[following].append((start + k, step_weight))

    def nearest(point, start, count):
        return start + min(range(count), key=lambda k: math.hypot(points[start + k][0] - point[0],
                                                                  points[start + k][1] - point[1]))

    home_index = min([nearest(home, 0, len(points1)), nearest(home, offset, len(points2))],
                     key=lambda index: math.hypot(points[index][0] - home[0], points[index][1] - home[1]))
    school_index = min([nearest(school, 0, len(points1)), nearest(school, offset, len(points2))],
                       key=lambda index: math.hypot(points[index][0] - school[0], points[index][1] - school[1]))
    for source, point in enumerate(points1):
        if abs(math.hypot(point[0] - cx2, point[1] - cy2) - radius2) < 2 * math.pi * radius1 / steps:
            match = nearest(point, offset, len(points2))
            if math.hypot(points[match][0] - point[0], points[match][1] - point[1]) < 2 * math.pi * radius2 / steps:
                neighbours[source].append((match, 0.0))
                neighbours[match].append((source, 0.0))

    distances = [math.inf] * total
    distances[home_index] = 0.0
    queue = [(0.0, home_index)]
    while queue:
        current_dist, current = heapq.heappop(queue)
        if current_dist > distances[current]:
            continue
        for following, weight in neighbours[current]:
            candidate = current_dist + weight
            if candidate < distances[following]:
                distances[following] = candidate
                heapq.heappush(queue, (candidate, following))
    return distances[school_index]


def point_on(circle, angle):
    cx, cy, radius = circle
    return (cx + radius * math.cos(angle), cy + radius * math.sin(angle))


def as_text(cases):
    lines = [str(len(cases))]
    for first_circle, second_circle, home, school in cases:
        lines.append("{} {} {}".format(*first_circle))
        lines.append("{} {} {}".format(*second_circle))
        lines.append("{:.15f} {:.15f}".format(*home))
        lines.append("{:.15f} {:.15f}".format(*school))
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = SAMPLE_IN if name == "1_sample" else as_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(SAMPLE_OUT if name == "1_sample" else oracle(input_text))


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert solve_case((0, 0, 5), (0, 0, 5), (5.0, 0.0), (-5.0, 0.0)) == fmt(5 * math.pi)
assert solve_case((0, 0, 5), (8, 0, 3), (0.0, 5.0), (8.0, 3.0)) == fmt(4 * math.pi)
assert solve_case((0, 0, 5), (0, 0, 3), (5.0, 0.0), (0.0, 3.0)) == "-1"
assert solve_case((0, 0, 0), (20, 0, 3), (0.0, 0.0), (20.0, 3.0)) == "-1"
assert solve_case((0, 0, 5), (4, 0, 3), (4.0, 3.0), (7.0, 0.0)) == fmt(3 * math.pi / 2)
for checked in [((0, 0, 5), (4, 0, 3), point_on((0, 0, 5), 1.1), point_on((4, 0, 3), 2.0)),
                ((0, 0, 5), (0, 0, 5), point_on((0, 0, 5), 0.2), point_on((0, 0, 5), 2.9))]:
    dense = brute_dense(*checked)
    exact = float(solve_case(*checked))
    assert abs(dense - exact) < 0.1, (dense, exact)


def build():
    edges = [
        ((0, 0, 5), (12, 0, 5), (5.0, 0.0), (5.0, 0.0)),
        ((0, 0, 0), (20, 0, 3), (0.0, 0.0), (20.0, 3.0)),
        ((0, 0, 5), (0, 0, 3), (5.0, 0.0), (0.0, 3.0)),
        ((0, 0, 5), (0, 0, 5), (5.0, 0.0), (-5.0, 0.0)),
        ((0, 0, 5), (8, 0, 3), (0.0, 5.0), (8.0, 3.0)),
        ((0, 0, 5), (2, 0, 3), (0.0, 5.0), (5.0, 0.0)),
        ((0, 0, 5), (4, 0, 3), (4.0, 3.0), point_on((4, 0, 3), 2.0)),
        ((0, 0, 0), (0, 0, 0), (0.0, 0.0), (0.0, 0.0)),
        ((0, 0, 5), (4, 0, 3), point_on((0, 0, 5), 5.9), point_on((0, 0, 5), 0.5)),
        ((0, 0, 0), (5, 0, 5), (0.0, 0.0), (8.0, 0.0)),
        ((0, 0, 0), (5, 0, 5), (0.0, 0.0), (5.0, 5.0)),
        ((0, 0, 0), (5, 0, 6), (0.0, 0.0), (5.0, 6.0)),
        ((0, 0, 0), (5, 0, 0), (0.0, 0.0), (5.0, 0.0)),
        ((0, 0, 5), (4, 0, 3), (4.0, 3.0), (4.0, 3.0)),
    ]
    write("2_edges", edges)

    wide = [
        ((-200, -200, 200), (200, 200, 200), point_on((-200, -200, 200), 1.0), point_on((200, 200, 200), 2.0)),
        ((-200, 0, 200), (200, 0, 200), point_on((-200, 0, 200), 1.57), point_on((200, 0, 200), 4.71)),
        ((0, 0, 200), (50, 0, 150), point_on((0, 0, 200), 0.7), point_on((50, 0, 150), 2.4)),
        ((200, 200, 200), (200, 200, 199), point_on((200, 200, 200), 0.3), point_on((200, 200, 199), 3.1)),
        ((-200, 200, 0), (200, -200, 200), (-200.0, 200.0), point_on((200, -200, 200), 2.2)),
        ((0, 0, 200), (0, 0, 200), point_on((0, 0, 200), 0.8), point_on((0, 0, 200), 4.0)),
        ((0, 0, 200), (1, 0, 200), point_on((0, 0, 200), 1.9), point_on((1, 0, 200), 4.9)),
        ((200, -200, 200), (-200, 200, 100), point_on((200, -200, 200), 3.7), point_on((-200, 200, 100), 0.1)),
    ]
    write("3_wide", wide)

    random.seed(20261124)

    def random_case():
        first_circle = (random.randint(-200, 200), random.randint(-200, 200), random.randint(0, 200))
        second_circle = (random.randint(-200, 200), random.randint(-200, 200), random.randint(0, 200))
        home = point_on(first_circle if random.randint(1, 2) == 1 else second_circle, random.uniform(0, 2 * math.pi))
        school = point_on(first_circle if random.randint(1, 2) == 1 else second_circle, random.uniform(0, 2 * math.pi))
        return first_circle, second_circle, home, school

    write("4_random", [random_case() for _ in range(100)])
    write("5_io", [random_case() for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [])
build()
