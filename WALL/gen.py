#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def polygon_area(points):
    total = 0
    for index, current in enumerate(points):
        following = points[(index + 1) % len(points)]
        total += current[0] * following[1] - following[0] * current[1]
    return abs(total) / 2


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    case_number = 0
    while True:
        vertex_count = tokens[cursor]; cursor += 1
        budget = tokens[cursor]; cursor += 1
        if vertex_count == 0 and budget == 0:
            break
        case_number += 1
        points = [(tokens[cursor + index * 2], tokens[cursor + index * 2 + 1])
                  for index in range(vertex_count)]
        cursor += vertex_count * 2
        best = 0.0
        for mask in range(1 << vertex_count):
            chosen = [index for index in range(vertex_count) if mask >> index & 1]
            if len(chosen) < 3:
                continue
            wall_length = 0.0
            for current, following in zip(chosen, chosen[1:] + chosen[:1]):
                if (following - current) % vertex_count != 1:
                    wall_length += math.dist(points[current], points[following])
            if wall_length > budget + 1e-9:
                continue
            area = polygon_area([points[index] for index in chosen])
            if area > best:
                best = area
        answers.append('Case {}: {:.1f}'.format(case_number, best))
    return ''.join(answer + '\n' for answer in answers)


SAMPLE_IN = '''5 4
0 0
4 0
4 4
2 2
0 4
8 80
45 41
70 31
86 61
72 64
80 79
40 80
8 94
28 22
0 0
'''
SAMPLE_OUT = '''Case 1: 16.0
Case 2: 3375.0
'''
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle('5 0\n0 0\n4 0\n4 4\n2 2\n0 4\n0 0\n') == 'Case 1: 12.0\n'
assert oracle('5 100\n0 0\n4 0\n4 4\n2 2\n0 4\n0 0\n') == 'Case 1: 16.0\n'
assert polygon_area([(0, 0), (4, 0), (4, 4), (2, 2), (0, 4)]) == 12.0
assert math.dist((0, 0), (3, 4)) == 5.0


def write(name, cases):
    lines = []
    for budget, points in cases:
        lines.append('{} {}'.format(len(points), budget))
        lines.extend('{} {}'.format(x, y) for x, y in points)
    lines.append('0 0')
    text = '\n'.join(lines) + '\n'
    (ROOT / 'in' / '{}.txt'.format(name)).write_text(text)
    (ROOT / 'out' / '{}.out'.format(name)).write_text(oracle(text))


def star_polygon(rng, vertex_count):
    angles = sorted(rng.uniform(0, 2 * math.pi) for _ in range(vertex_count))
    points = []
    for angle in angles:
        radius = rng.randint(18, 48)
        points.append((int(50 + radius * math.cos(angle)),
                       int(50 + radius * math.sin(angle))))
    if len(set(points)) != vertex_count:
        return None
    return points


def build():
    notch = [(0, 0), (4, 0), (4, 4), (2, 2), (0, 4)]
    write('2_edges', [
        (0, notch), (3, notch), (4, notch), (100, notch),
        (0, [(0, 0), (10, 0), (10, 10), (5, 4), (0, 10)]),
    ])
    wide = star_polygon(random.Random(99), 10)
    write('3_wide', [(0, wide), (50, wide), (200, wide), (400, wide)])
    rng = random.Random(20261126)
    cases = []
    while len(cases) < 40:
        points = star_polygon(rng, rng.randint(5, 10))
        if points is None:
            continue
        cases.append((rng.randint(0, 200), points))
    write('4_random', cases)
    cases = []
    while len(cases) < 200:
        points = star_polygon(rng, 10)
        if points is None:
            continue
        cases.append((rng.randint(0, 400), points))
    write('5_io', cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_IN)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
