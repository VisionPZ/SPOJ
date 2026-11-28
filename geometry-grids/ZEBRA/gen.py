#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RADIANS_PER_MINUTE = math.pi / 10800.0
EPS = 1e-10


def exact_tan(angle):
    if angle == 0:
        return 0.0
    if angle == 2700:
        return 1.0
    if angle == -2700:
        return -1.0
    return math.tan(angle * RADIANS_PER_MINUTE)


def far_side(bottom, angle, width):
    return bottom + exact_tan(angle) * width


def oracle_case(width, speed, people):
    forbidden_x = {bottom for bottom, crossing, angle in people}
    groups = {}
    for bottom, crossing, angle in people:
        groups.setdefault(crossing, []).append((bottom, angle))
    best = 0
    for crossing, walkers in groups.items():
        reach = speed * crossing
        if reach < width:
            continue
        displacement = math.sqrt(float(reach) ** 2 - float(width) ** 2)
        items = [(bottom, far_side(bottom, angle, width)) for bottom, angle in walkers]
        xs = sorted(bottom for bottom, _ in items)
        fars = sorted(f for _, f in items)
        marks = sorted(set(fars + xs + [x - displacement for x in xs] + [x + displacement for x in xs]))
        qs = set()
        for m in marks:
            qs.add(m)
            qs.add(m - 1e-5)
            qs.add(m + 1e-5)
        for i in range(len(marks) - 1):
            qs.add((marks[i] + marks[i + 1]) / 2.0)
        for q in qs:
            cands_s = set()
            if displacement == 0.0:
                if all(abs(q - fx) > EPS for fx in forbidden_x):
                    cands_s.add(q)
            else:
                lo, hi = q - displacement, q + displacement
                pts = [lo, hi] + [x for x in xs if lo < x < hi]
                pts.sort()
                for p in pts:
                    if lo <= p - 1e-6 <= hi:
                        cands_s.add(p - 1e-6)
                    if lo <= p + 1e-6 <= hi:
                        cands_s.add(p + 1e-6)
                for i in range(len(pts) - 1):
                    cands_s.add((pts[i] + pts[i + 1]) / 2.0)
            for s in cands_s:
                if abs(q - s) > displacement + EPS:
                    continue
                if any(abs(s - fx) <= EPS for fx in forbidden_x):
                    continue
                hits = 0
                for bottom, top in items:
                    if s < bottom and q >= top - EPS:
                        hits += 1
                    elif s > bottom and q <= top + EPS:
                        hits += 1
                if hits > best:
                    best = hits
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
assert oracle_case(20, 2, [(-20, 10, 2700), (20, 10, -2700), (0, 1, 0)]) == 1
assert oracle_case(20, 2, [(-20, 10, 2700), (0, 10, 0)]) == 1
assert oracle_case(10, 10, [(0, 1, 0)]) == 0
assert oracle_case(10, 10, [(0, 1, 2700)]) == 1
assert oracle_case(10, 20, [(-5, 1, 2700), (5, 1, -2700)]) == 2
assert oracle_case(10, 20, [(0, 1, 0)]) == 1

random.seed(20261124)
EDGE_CASES = [
    (10, 1, [(0, 5, 0)]),
    (10, 10, [(0, 1, 0)]),
    (10, 10, [(0, 1, 2700)]),
    (20, 2, [(-20, 10, 2700), (20, 10, -2700), (0, 1, 0)]),
    (20, 2, [(-20, 10, 2700), (0, 10, 0)]),
    (10, 20, [(0, 1, 3600)]),
    (10, 20, [(-5, 1, 2700), (5, 1, -2700)]),
    (100, 10000, [(-10000, 10000, 0), (10000, 10000, 0)]),
    (1, 10000, [(0, 1, 5000), (1, 1, -5000), (-1, 2, 0)]),
    (100, 2, [(-10000, 100, 5000), (10000, 100, -5000), (0, 50, 0)]),
    (7, 13, [(x, 3, angle) for x, angle in zip(range(-9, 0), [0, 60, -60, 4000, -4000, 5000, -5000, 2700, -2700])]),
    (50, 5, [(-56, 10, -1), (-6, 10, -2700)]),
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
