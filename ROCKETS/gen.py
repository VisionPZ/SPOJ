#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PRIME = 19997
SHIFT = (PRIME - 1) // 2


def cross(first, second, third):
    return ((second[0] - first[0]) * (third[1] - first[1])
            - (second[1] - first[1]) * (third[0] - first[0]))


def on_segment(first, middle, second):
    return (min(first[0], second[0]) <= middle[0] <= max(first[0], second[0])
            and min(first[1], second[1]) <= middle[1] <= max(first[1], second[1]))


def segments_touch(first, second, third, fourth):
    a = cross(first, second, third)
    b = cross(first, second, fourth)
    c = cross(third, fourth, first)
    d = cross(third, fourth, second)
    if ((a > 0 and b < 0) or (a < 0 and b > 0)) and ((c > 0 and d < 0) or (c < 0 and d > 0)):
        return True
    return ((a == 0 and on_segment(first, third, second))
            or (b == 0 and on_segment(first, fourth, second))
            or (c == 0 and on_segment(third, first, fourth))
            or (d == 0 and on_segment(third, second, fourth)))


def no_three_collinear(points):
    seen = set()
    for i in range(len(points)):
        for j in range(i + 1, len(points)):
            first = points[i]
            second = points[j]
            delta_x = second[0] - first[0]
            delta_y = second[1] - first[1]
            divisor = math.gcd(abs(delta_x), abs(delta_y))
            delta_x //= divisor
            delta_y //= divisor
            if delta_x < 0 or (delta_x == 0 and delta_y < 0):
                delta_x = -delta_x
                delta_y = -delta_y
            intercept = delta_x * first[1] - delta_y * first[0]
            key = (delta_x, delta_y, intercept)
            if key in seen:
                return False
            seen.add(key)
    return True


def parabola_points(count, rng):
    values = rng.sample(range(PRIME), count)
    return [(x - SHIFT, (x * x) % PRIME - SHIFT) for x in values]


def random_points(count, rng):
    while True:
        columns = rng.sample(range(-10000, 10001), count)
        result = [(x, rng.randint(-10000, 10000)) for x in columns]
        if no_three_collinear(result):
            return result


def oracle(case):
    points = case
    count = len(points) // 2
    answer = [0] * (count + 1)
    ids = list(range(len(points)))
    pending = [(0, len(points))]
    while pending:
        lo, hi = pending.pop()
        if hi <= lo:
            continue
        best = min(range(lo, hi), key=lambda i: (points[ids[i]][0], points[ids[i]][1]))
        ids[lo], ids[best] = ids[best], ids[lo]
        pivot = ids[lo]
        pivot_x, pivot_y = points[pivot][0], points[pivot][1]
        ordered = sorted(ids[lo + 1:hi],
                         key=lambda q: math.atan2(points[q][1] - pivot_y,
                                                  points[q][0] - pivot_x))
        ids[lo + 1:hi] = ordered
        balance = 0
        match_position = lo + 1
        best_distance = hi - lo
        middle = (lo + hi) // 2
        for i in range(lo + 1, hi):
            other = ids[i]
            if points[other][2] == points[pivot][2]:
                balance += 1
            else:
                if balance == 0:
                    distance = abs(i - middle)
                    if distance < best_distance:
                        best_distance = distance
                        match_position = i
                balance -= 1
        target = ids[match_position]
        if points[pivot][2] == 0:
            answer[points[pivot][3]] = points[target][3]
        else:
            answer[points[target][3]] = points[pivot][3]
        pending.append((lo + 1, match_position))
        pending.append((match_position + 1, hi))
    return answer


def validate(case, answer, full=True):
    count = len(case) // 2
    assert sorted(answer[1:]) == list(range(1, count + 1)), 'answer is not a permutation'
    segments = []
    for rocket in range(count):
        target = answer[rocket + 1] - 1
        rocket_point = case[rocket]
        target_point = case[count + target]
        segments.append((rocket_point[:2], target_point[:2]))
    if full:
        for i in range(len(segments)):
            for j in range(i + 1, len(segments)):
                assert not segments_touch(segments[i][0], segments[i][1],
                                          segments[j][0], segments[j][1]), 'segments intersect'
    else:
        rng = random.Random(7)
        for _ in range(4000):
            i = rng.randrange(len(segments))
            j = rng.randrange(len(segments))
            if i != j:
                assert not segments_touch(segments[i][0], segments[i][1],
                                          segments[j][0], segments[j][1]), 'segments intersect'
    return True


def make_case(points):
    count = len(points) // 2
    result = []
    for i, point in enumerate(points):
        color = 0 if i < count else 1
        result.append((point[0], point[1], color, (i % count) + 1))
    return result


def case_text(cases):
    chunks = []
    for case in cases:
        lines = [str(len(case) // 2)]
        for point in case:
            lines.append(f'{point[0]} {point[1]}')
        chunks.append('\n'.join(lines) + '\n')
    return str(len(cases)) + '\n' + '\n'.join(chunks)


def answer_text(cases):
    lines = []
    for case in cases:
        answer = oracle(case)
        validate(case, answer, full=len(case) // 2 <= 400)
        lines.extend(str(value) for value in answer[1:])
    return '\n'.join(lines) + '\n'


def write(name, cases):
    text = case_text(cases)
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(answer_text(cases))


SAMPLE_POINTS = [(0, 0), (1, 5), (4, 2), (2, 6), (1, 2), (5, 4), (4, 5), (3, 1)]
SAMPLE_INPUT = ('1\n4\n0 0\n1 5\n4 2\n2 6\n1 2\n5 4\n4 5\n3 1\n')
SAMPLE_OUTPUT = '2\n1\n4\n3\n'

sample_case = make_case(SAMPLE_POINTS)
assert oracle(sample_case)[1:] == [2, 1, 4, 3]
assert no_three_collinear(SAMPLE_POINTS)
assert len(parabola_points(PRIME, random.Random(1))) == PRIME
assert no_three_collinear(parabola_points(90, random.Random(2)))
assert validate(sample_case, oracle(sample_case))


def build():
    rng = random.Random(20261124)

    edges = []
    edges.append(make_case([(4, 1), (-3, -2)]))
    edges.append(make_case([(-5, 4), (-7, 9), (3, -1), (8, 2)]))
    edges.append(make_case([(-2, 7), (-9, 3), (6, -4), (1, 8), (10, -8), (0, 5)]))
    edge_points = parabola_points(8, rng)
    edges.append(make_case(edge_points[:4] + edge_points[4:]))
    write('2_edges', edges)

    wide_points = parabola_points(2 * 9998, random.Random(31))
    left_first = sorted(wide_points, key=lambda point: (point[0], point[1]))
    wide_a = make_case(left_first[:9998] + left_first[9998:])
    wide_b = make_case([wide_points[i] for i in range(0, 2 * 9998, 2)]
                       + [wide_points[i] for i in range(1, 2 * 9998, 2)])
    write('3_wide', [wide_a, wide_b])

    mixed = []
    for count in (1, 2, 3, 5, 10, 40, 150, 400):
        points = random_points(2 * count, rng)
        mixed.append(make_case(points))
    for count in (7, 60, 300):
        points = parabola_points(2 * count, rng)
        rng.shuffle(points)
        mixed.append(make_case(points))
    write('4_random', mixed)

    io_cases = []
    for _ in range(8):
        points = parabola_points(2 * 9998, rng)
        rng.shuffle(points)
        io_cases.append(make_case(points))
    write('5_io', io_cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_INPUT)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUTPUT)
build()
