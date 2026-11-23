import math
import random
from pathlib import Path

import numpy as np

BASE = Path(__file__).resolve().parent
ROUNDING_EPSILON = 1e-7


def format_answer(point_x, point_y):
    scaled_x = math.floor(point_x * 10.0 + 0.5 + ROUNDING_EPSILON)
    scaled_y = math.floor(point_y * 10.0 + 0.5 + ROUNDING_EPSILON)
    scaled_x = max(0, scaled_x)
    scaled_y = max(0, scaled_y)
    return "The safest point is (%d.%d, %d.%d).\n" % (
        scaled_x // 10, scaled_x % 10, scaled_y // 10, scaled_y % 10)


def nearest_squared(point_x, point_y, holes):
    return min((point_x - hole_x) ** 2 + (point_y - hole_y) ** 2
               for hole_x, hole_y in holes)


def is_better(distance, point, best_distance, best_point):
    if distance > best_distance + 1e-7:
        return True
    if abs(distance - best_distance) > 1e-7:
        return False
    if point[0] < best_point[0] - 1e-7:
        return True
    if abs(point[0] - best_point[0]) > 1e-7:
        return False
    return point[1] < best_point[1] - 1e-7


def circumcenter(first, second, third):
    x1, y1 = first
    x2, y2 = second
    x3, y3 = third
    denominator = 2.0 * ((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1))
    if abs(denominator) < 1e-12:
        return None
    first_power = x2 * x2 + y2 * y2 - x1 * x1 - y1 * y1
    second_power = x3 * x3 + y3 * y3 - x1 * x1 - y1 * y1
    center_x = (first_power * (y3 - y1) - second_power * (y2 - y1)) / denominator
    center_y = ((x2 - x1) * second_power - (x3 - x1) * first_power) / denominator
    return center_x, center_y


def exact_oracle(room_x, room_y, holes):
    unique_holes = sorted(set(holes))
    candidates = [(0.0, 0.0), (float(room_x), 0.0),
                  (0.0, float(room_y)), (float(room_x), float(room_y))]
    for index, (x1, y1) in enumerate(unique_holes):
        for x2, y2 in unique_holes[index + 1:]:
            right_side = (x2 * x2 + y2 * y2 - x1 * x1 - y1 * y1) / 2.0
            delta_x = x2 - x1
            delta_y = y2 - y1
            if abs(delta_y) > 1e-12:
                for edge_x in (0.0, float(room_x)):
                    edge_y = (right_side - delta_x * edge_x) / delta_y
                    if -1e-9 <= edge_y <= room_y + 1e-9:
                        candidates.append((edge_x, min(room_y, max(0.0, edge_y))))
            if abs(delta_x) > 1e-12:
                for edge_y in (0.0, float(room_y)):
                    edge_x = (right_side - delta_y * edge_y) / delta_x
                    if -1e-9 <= edge_x <= room_x + 1e-9:
                        candidates.append((min(room_x, max(0.0, edge_x)), edge_y))
    for first_index in range(len(unique_holes)):
        for second_index in range(first_index + 1, len(unique_holes)):
            for third_index in range(second_index + 1, len(unique_holes)):
                center = circumcenter(unique_holes[first_index],
                                      unique_holes[second_index],
                                      unique_holes[third_index])
                if center is not None and -1e-9 <= center[0] <= room_x + 1e-9 \
                        and -1e-9 <= center[1] <= room_y + 1e-9:
                    candidates.append((min(room_x, max(0.0, center[0])),
                                       min(room_y, max(0.0, center[1]))))
    best_distance = -1.0
    best_point = (0.0, 0.0)
    for candidate in candidates:
        distance = nearest_squared(candidate[0], candidate[1], unique_holes)
        if is_better(distance, candidate, best_distance, best_point):
            best_distance = distance
            best_point = candidate
    return best_point[0], best_point[1], best_distance


def polish_point(room_x, room_y, holes, point_x, point_y):
    unique_holes = sorted(set(holes))
    ranked = sorted(unique_holes,
                    key=lambda hole: (point_x - hole[0]) ** 2 + (point_y - hole[1]) ** 2)[:6]
    candidates = [(0.0, 0.0), (float(room_x), 0.0),
                  (0.0, float(room_y)), (float(room_x), float(room_y))]
    for first_index, (x1, y1) in enumerate(ranked):
        for x2, y2 in ranked[first_index + 1:]:
            right_side = (x2 * x2 + y2 * y2 - x1 * x1 - y1 * y1) / 2.0
            delta_x = x2 - x1
            delta_y = y2 - y1
            if abs(delta_y) > 1e-12:
                for edge_x in (0.0, float(room_x)):
                    edge_y = (right_side - delta_x * edge_x) / delta_y
                    if -1e-9 <= edge_y <= room_y + 1e-9:
                        candidates.append((edge_x, min(room_y, max(0.0, edge_y))))
            if abs(delta_x) > 1e-12:
                for edge_y in (0.0, float(room_y)):
                    edge_x = (right_side - delta_y * edge_y) / delta_x
                    if -1e-9 <= edge_x <= room_x + 1e-9:
                        candidates.append((min(room_x, max(0.0, edge_x)), edge_y))
    for first_index in range(len(ranked)):
        for second_index in range(first_index + 1, len(ranked)):
            for third_index in range(second_index + 1, len(ranked)):
                center = circumcenter(ranked[first_index], ranked[second_index],
                                      ranked[third_index])
                if center is not None and -1e-9 <= center[0] <= room_x + 1e-9 \
                        and -1e-9 <= center[1] <= room_y + 1e-9:
                    candidates.append((min(room_x, max(0.0, center[0])),
                                       min(room_y, max(0.0, center[1]))))
    best_distance = nearest_squared(point_x, point_y, unique_holes)
    best_point = (point_x, point_y)
    for candidate in candidates:
        distance = nearest_squared(candidate[0], candidate[1], unique_holes)
        if is_better(distance, candidate, best_distance, best_point):
            best_distance = distance
            best_point = candidate
    return best_point[0], best_point[1], best_distance


def grid_oracle(room_x, room_y, holes, step):
    unique_holes = sorted(set(holes))
    hole_array = np.asarray(unique_holes, dtype=np.float64)
    x_count = int(room_x / step) + 1
    y_count = int(room_y / step) + 1
    grid_x = np.linspace(0.0, float(room_x), x_count)
    grid_y = np.linspace(0.0, float(room_y), y_count)
    best_grid = np.full((x_count, y_count), np.inf)
    for hole_x, hole_y in hole_array:
        squared = (grid_x[:, None] - hole_x) ** 2 + (grid_y[None, :] - hole_y) ** 2
        np.minimum(best_grid, squared, out=best_grid)
    flat_order = np.argsort(best_grid.ravel())[::-1]
    starts = []
    for flat_index in flat_order:
        x_index = int(flat_index) // y_count
        y_index = int(flat_index) % y_count
        start = (float(grid_x[x_index]), float(grid_y[y_index]))
        if all((start[0] - other[0]) ** 2 + (start[1] - other[1]) ** 2 > 1.0
               for other in starts):
            starts.append(start)
        if len(starts) == 8:
            break
    best_distance = -1.0
    best_point = starts[0]
    for start in starts:
        point_x, point_y = start
        distance = nearest_squared(point_x, point_y, unique_holes)
        current_step = step / 2.0
        while current_step > 0.002:
            improved = False
            for delta_x in (-current_step, 0.0, current_step):
                for delta_y in (-current_step, 0.0, current_step):
                    trial_x = min(room_x, max(0.0, point_x + delta_x))
                    trial_y = min(room_y, max(0.0, point_y + delta_y))
                    trial_distance = nearest_squared(trial_x, trial_y, unique_holes)
                    if trial_distance > distance + 1e-9:
                        distance = trial_distance
                        point_x, point_y = trial_x, trial_y
                        improved = True
            if not improved:
                current_step /= 2.0
        if is_better(distance, (point_x, point_y), best_distance, best_point):
            best_distance = distance
            best_point = (point_x, point_y)
    polished = polish_point(room_x, room_y, unique_holes, best_point[0], best_point[1])
    if is_better(polished[2], (polished[0], polished[1]), best_distance, best_point):
        best_distance = polished[2]
        best_point = (polished[0], polished[1])
    return best_point[0], best_point[1], best_distance


def unique_optimum(room_x, room_y, holes, point_x, point_y, best_distance):
    unique_holes = sorted(set(holes))
    sensors = [(0.0, 0.0), (float(room_x), 0.0),
               (0.0, float(room_y)), (float(room_x), float(room_y))]
    for offset in (0.05, 0.15, 0.5, 1.0, 2.0, 5.0, 20.0):
        for delta_x in (-offset, 0.0, offset):
            for delta_y in (-offset, 0.0, offset):
                sensor_x = min(room_x, max(0.0, point_x + delta_x))
                sensor_y = min(room_y, max(0.0, point_y + delta_y))
                sensors.append((sensor_x, sensor_y))
    for sensor_x, sensor_y in sensors:
        if (sensor_x - point_x) ** 2 + (sensor_y - point_y) ** 2 < 0.01:
            continue
        distance = nearest_squared(sensor_x, sensor_y, unique_holes)
        if distance > best_distance - 1e-6:
            return False
    return True


SAMPLE_INPUT = """3
1000 50 1
10 10
100 100 4
10 10
10 90
90 10
90 90
3000 3000 4
1200 85
63 2500
2700 2650
2990 100
"""
SAMPLE_OUTPUT = """The safest point is (1000.0, 50.0).
The safest point is (50.0, 50.0).
The safest point is (1433.0, 1669.8).
"""


def write_case(name, cases):
    lines = [str(len(cases))]
    answers = []
    for room_x, room_y, holes in cases:
        lines.append("%d %d %d" % (room_x, room_y, len(holes)))
        for hole_x, hole_y in holes:
            lines.append("%d %d" % (hole_x, hole_y))
        if len(set(holes)) > 25:
            point_x, point_y, _ = grid_oracle(room_x, room_y, holes, 40.0)
        else:
            point_x, point_y, _ = exact_oracle(room_x, room_y, holes)
        answers.append(format_answer(point_x, point_y))
    (BASE / "in" / (name + ".txt")).write_text("\n".join(lines) + "\n")
    (BASE / "out" / (name + ".out")).write_text("".join(answers))


def run_asserts():
    assert SAMPLE_INPUT.count("\n") == 13
    assert format_answer(1000.0, 50.0) == "The safest point is (1000.0, 50.0).\n"
    assert format_answer(1669.8463, 1432.9876) == "The safest point is (1669.8, 1433.0).\n"
    known = [
        (1000, 50, [(10, 10)], (1000.0, 50.0)),
        (100, 100, [(10, 10), (10, 90), (90, 10), (90, 90)], (50.0, 50.0)),
        (3000, 3000, [(1200, 85), (63, 2500), (2700, 2650), (2990, 100)],
         (1433.0, 1669.8)),
        (1, 1, [(0, 0)], (1.0, 1.0)),
        (10, 10, [(5, 5), (5, 5), (5, 5)], (0.0, 0.0)),
        (15, 10, [(0, 5), (5, 5), (10, 5), (15, 5)], (2.5, 0.0)),
    ]
    for room_x, room_y, holes, expected in known:
        point_x, point_y, _ = exact_oracle(room_x, room_y, holes)
        assert format_answer(point_x, point_y) == format_answer(*expected), (room_x, room_y, holes)
    cross_rng = random.Random(93)
    for _ in range(12):
        room_x = cross_rng.randint(4, 24)
        room_y = cross_rng.randint(4, 24)
        holes = [(cross_rng.randint(0, room_x), cross_rng.randint(0, room_y))
                 for _ in range(cross_rng.randint(1, 7))]
        exact = exact_oracle(room_x, room_y, holes)
        coarse = grid_oracle(room_x, room_y, holes, 0.5)
        assert abs(math.sqrt(exact[2]) - math.sqrt(coarse[2])) < 0.2, (holes, exact, coarse)


def build_edges():
    cases = [
        (1, 1, [(0, 0)]),
        (1, 1, [(1, 1)]),
        (2, 3, [(0, 0), (2, 3)]),
        (5, 1, [(0, 0)]),
        (1, 5, [(0, 5)]),
        (10, 10, [(2, 3), (2, 3), (7, 4)]),
        (15, 10, [(0, 3), (4, 3), (11, 3), (14, 3)]),
        (10, 10, [(3, 0), (3, 4), (3, 10)]),
        (12, 9, [(0, 0), (12, 0), (0, 9), (12, 9), (6, 4)]),
        (7, 11, [(0, 0), (7, 0), (0, 11), (7, 11), (3, 5), (3, 5)]),
        (30, 20, [(0, 0), (10, 20)]),
        (30, 20, [(30, 0), (0, 10)]),
    ]
    checked = []
    for room_x, room_y, holes in cases:
        point_x, point_y, distance = exact_oracle(room_x, room_y, holes)
        assert unique_optimum(room_x, room_y, holes, point_x, point_y, distance), (room_x, room_y, holes)
        checked.append((room_x, room_y, holes))
    return checked


def build_wide(rng):
    cases = []
    room_x = 10000
    room_y = 10000
    holes = [(rng.randint(0, room_x), rng.randint(0, room_y)) for _ in range(1000)]
    point_x, point_y, distance = grid_oracle(room_x, room_y, holes, 40.0)
    cases.append((room_x, room_y, holes))
    wide_checks.append((room_x, room_y, holes, point_x, point_y, distance))
    for room_x, room_y in ((10000, 1), (1, 10000), (10000, 10000), (9999, 7777)):
        hole_count = rng.randint(4, 18)
        holes = [(rng.randint(0, room_x), rng.randint(0, room_y))
                 for _ in range(hole_count)]
        point_x, point_y, distance = exact_oracle(room_x, room_y, holes)
        assert unique_optimum(room_x, room_y, holes, point_x, point_y, distance)
        cases.append((room_x, room_y, holes))
    return cases


def build_random(rng):
    cases = []
    attempts = 0
    while len(cases) < 70 and attempts < 5000:
        attempts += 1
        room_x = rng.randint(1, 300)
        room_y = rng.randint(1, 300)
        hole_count = rng.randint(1, 16)
        holes = [(rng.randint(0, room_x), rng.randint(0, room_y))
                 for _ in range(hole_count)]
        if attempts % 9 == 0:
            holes.append(holes[0])
        point_x, point_y, distance = exact_oracle(room_x, room_y, holes)
        if not unique_optimum(room_x, room_y, holes, point_x, point_y, distance):
            continue
        cases.append((room_x, room_y, holes))
    assert len(cases) == 70
    return cases


def build_io(rng):
    cases = []
    for index in range(20000):
        room_x = rng.randint(1, 10000)
        room_y = rng.randint(1, 10000)
        hole_x = rng.randint(0, room_x)
        hole_y = rng.randint(0, room_y)
        cases.append((room_x, room_y, [(hole_x, hole_y)]))
    return cases


wide_checks = []
run_asserts()
rng = random.Random(20261123)
write_case("1_sample", [(1000, 50, [(10, 10)]),
                        (100, 100, [(10, 10), (10, 90), (90, 10), (90, 90)]),
                        (3000, 3000, [(1200, 85), (63, 2500), (2700, 2650), (2990, 100)])])
assert (BASE / "in" / "1_sample.txt").read_text() == SAMPLE_INPUT
assert (BASE / "out" / "1_sample.out").read_text() == SAMPLE_OUTPUT
write_case("2_edges", build_edges())
write_case("3_wide", build_wide(rng))
write_case("4_random", build_random(rng))
write_case("5_io", build_io(rng))
print("generated five cases; wide checks", len(wide_checks))
