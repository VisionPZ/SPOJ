#!/usr/bin/env python3
import itertools
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RADIANS_PER_MINUTE = math.pi / 10800.0
NEAR_ZERO = 1e-7
SMALL_CASE = 12


def far_side(bottom, angle, width):
    return bottom + math.tan(angle * RADIANS_PER_MINUTE) * width


def solve_linear(rows):
    size = 4
    matrix = [list(row[0]) + [row[1]] for row in rows]
    for column in range(size):
        pivot = None
        for index in range(column, len(matrix)):
            if abs(matrix[index][column]) > 1e-10:
                pivot = index
                break
        if pivot is None:
            return None
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        scale = matrix[column][column]
        matrix[column] = [value / scale for value in matrix[column]]
        for index in range(len(matrix)):
            if index != column and abs(matrix[index][column]) > 1e-15:
                factor = matrix[index][column]
                matrix[index] = [matrix[index][k] - factor * matrix[column][k]
                                 for k in range(size + 1)]
    for row in matrix[size:]:
        if abs(row[size]) > 1e-5:
            return None
    return [row[size] for row in matrix[:size]]


def count_collisions(width, speed, people, far_sides, strategy):
    start, finish_time, delay, combined = strategy
    if delay <= NEAR_ZERO or delay > finish_time + NEAR_ZERO:
        return 0
    far_x = (combined + start * finish_time) / delay
    duration = finish_time - delay
    horizontal = far_x - start
    if speed * duration + NEAR_ZERO < math.hypot(width, horizontal):
        return 0
    if any(abs(start - person[0]) < 1e-6 for person in people):
        return 0
    hits = 0
    for (bottom, crossing, angle), far_value in zip(people, far_sides):
        if crossing > duration + NEAR_ZERO:
            ratio = delay / (crossing - duration)
            if ratio <= 1 + NEAR_ZERO:
                if abs(start + horizontal * ratio -
                       (bottom + (far_value - bottom) * ratio)) < 1e-6:
                    hits += 1
        elif crossing >= duration - NEAR_ZERO and delay <= NEAR_ZERO:
            denominator = horizontal - (far_value - bottom)
            if abs(denominator) > NEAR_ZERO:
                ratio = (bottom - start) / denominator
                if -NEAR_ZERO <= ratio <= 1 + NEAR_ZERO and abs(start - bottom) > NEAR_ZERO:
                    hits += 1
    return hits


def delayed_oracle(width, speed, people):
    count = len(people)
    if count == 0:
        return 0
    far_sides = [far_side(person[0], person[2], width) for person in people]
    rows = []
    for (bottom, crossing, angle), far_value in zip(people, far_sides):
        rows.append(((float(crossing), float(bottom), -far_value, 1.0),
                     float(bottom) * float(crossing)))
    delay_values = [0.0, 1.0, 2.0, 3.0]
    finish_values = []
    for person in people:
        crossing = float(person[1])
        delay_values.extend([crossing, crossing / 2.0, crossing - 1.0])
        finish_values.extend([crossing, crossing - 1.0, crossing - 2.0,
                              crossing - 3.0, crossing + 1.0, crossing / 2.0])
    delay_values = sorted(set(delay_values))
    finish_values = sorted(set(finish_values))
    best = 0
    for size in (4, 3, 2):
        for subset in itertools.combinations(range(count), size):
            base = [rows[index] for index in subset]
            if size == 4:
                candidates = [base]
            elif size == 3:
                candidates = [base + [((0.0, 0.0, 1.0, 0.0), value)]
                              for value in delay_values]
                candidates += [base + [((0.0, 1.0, 0.0, 0.0), value)]
                               for value in finish_values]
            else:
                candidates = []
                for delay_value in delay_values:
                    for finish_value in finish_values:
                        if finish_value > delay_value:
                            candidates.append(base + [((0.0, 0.0, 1.0, 0.0), delay_value),
                                                      ((0.0, 1.0, 0.0, 0.0), finish_value)])
            for system in candidates:
                solution = solve_linear(system)
                if solution is not None:
                    best = max(best, count_collisions(width, speed, people, far_sides, solution))
    return best


def synchronized_oracle(width, speed, people):
    groups = {}
    for bottom, crossing, angle in people:
        groups.setdefault(crossing, []).append((bottom, angle))
    best = 0
    for crossing, walkers in groups.items():
        reach = speed * crossing
        if reach < width:
            continue
        displacement = math.sqrt(float(reach) ** 2 - float(width) ** 2)
        bottoms = sorted(set(bottom for bottom, angle in walkers))
        far_sides = [far_side(bottom, angle, width) for bottom, angle in walkers]
        marks = sorted(set(bottoms + far_sides))
        candidates = list(marks)
        candidates += [value + shift for value in marks for shift in (-1e-6, 1e-6)]
        candidates += [(marks[k] + marks[k + 1]) / 2.0 for k in range(len(marks) - 1)]
        candidates += [marks[0] - 1, marks[-1] + 1]
        for start in candidates:
            choices = candidates + [start - displacement, start + displacement]
            for raw_end in choices:
                finish = max(start - displacement, min(start + displacement, raw_end))
                if abs(finish - start) > displacement + 1e-9:
                    continue
                hits = 0
                for bottom, angle in walkers:
                    top = far_side(bottom, angle, width)
                    if abs(start - bottom) < NEAR_ZERO:
                        continue
                    if start < bottom and finish >= top - 1e-9:
                        hits += 1
                    elif start > bottom and finish <= top + 1e-9:
                        hits += 1
                if hits > best:
                    best = hits
    return best


def oracle_case(width, speed, people):
    best = synchronized_oracle(width, speed, people)
    if len(people) <= SMALL_CASE:
        best = max(best, delayed_oracle(width, speed, people))
    return best


def write(name, cases, known_answers=None):
    lines = [str(len(cases))]
    for width, speed, people in cases:
        lines.append(f"{len(people)} {width} {speed}")
        for bottom, crossing, angle in people:
            lines.append(f"{bottom} {crossing} {angle}")
    input_text = "\n".join(lines) + "\n"
    if known_answers is None:
        answers = [oracle_case(width, speed, people) for width, speed, people in cases]
    else:
        answers = known_answers
    assert len(answers) == len(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text("".join(f"{answer}\n" for answer in answers))


SAMPLE = [
    (-20, 10, 2700),
    (20, 10, -2700),
    (-5, 1, 4000),
    (-4, 1, 4000),
    (5, 1, -4000),
]

assert oracle_case(20, 2, SAMPLE) == 2
assert oracle_case(5, 20, [(-2, 2, 2700), (2, 5, 2700)]) == 2
assert oracle_case(10, 10, [(0, 1, 0)]) == 0
assert oracle_case(10, 20, [(-5, 1, 2700), (5, 1, -2700)]) == 2
assert oracle_case(10, 20, [(0, 1, 0)]) == 1

random.seed(20261124)
EDGE_CASES = [
    (10, 1, [(0, 5, 0)]),
    (10, 10, [(0, 1, 0)]),
    (10, 20, [(-5, 1, 2700), (5, 1, -2700)]),
    (100, 10000, [(-10000, 10000, 0), (10000, 10000, 0)]),
    (1, 10000, [(0, 1, 5000), (1, 1, -5000), (-1, 2, 0)]),
    (100, 2, [(-10000, 100, 5000), (10000, 100, -5000), (0, 50, 0)]),
    (7, 13, [(x, 3, angle) for x, angle in zip(range(-9, 0), [0, 60, -60, 4000, -4000, 5000, -5000, 2700, -2700])]),
    (50, 5, [(-56, 10, -1), (-6, 10, -2700)]),
    (5, 20, [(-2, 2, 2700), (2, 5, 2700)]),
    (50, 100, [(18, 63, -2700), (-6, 53, 2700), (5, 64, 2700), (8, 88, 2700)]),
]

WIDE_CASES = []
for index in range(10):
    width = [1, 2, 10, 100, 1, 100, 7, 50, 100, 3][index]
    speed = [1, 100, 10000, 1, 10000, 100, 1, 10000, 7, 50][index]
    crossing = [1, 10000, 1, 10000, 100, 1, 10000, 5, 1, 10000][index]
    spots = random.sample(range(-10000, 10001), 25)
    people = [(x, crossing, random.randint(-5000, 5000)) for x in spots]
    WIDE_CASES.append((width, speed, people))

RANDOM_CASES = []
for index in range(100):
    width = random.randint(1, 100)
    speed = random.randint(1, 10000)
    spots = random.sample(range(-10000, 10001), random.randint(1, 20))
    people = [(x, random.randint(1, 10000),
               random.choice([0, 2700, -2700, 4000, -4000, 5000, -5000,
                              random.randint(-5000, 5000)])) for x in spots]
    RANDOM_CASES.append((width, speed, people))

IO_PEOPLE = [(x, 10000, 0) for x in range(-5000, 5000)]
IO_CASES = [(1, 10000, IO_PEOPLE) for index in range(100)]

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(20, 2, SAMPLE)])
write("2_edges", EDGE_CASES)
write("3_wide", WIDE_CASES)
write("4_random", RANDOM_CASES)
write("5_io", IO_CASES, [10000] * 100)
