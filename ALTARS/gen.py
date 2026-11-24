#!/usr/bin/env python3
from fractions import Fraction
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FACING = {'E': 0, 'N': 1, 'W': 2, 'S': 3}


def rotate_rect(rect, turns):
    minx, miny, maxx, maxy, facing = rect
    for _ in range(turns):
        minx, miny, maxx, maxy, facing = (
            -maxy, minx, -miny, maxx, (facing + 1) % 4)
    return minx, miny, maxx, maxy, facing


def oriented(rects, temple_index):
    turns = (4 - rects[temple_index][4]) % 4
    return [rotate_rect(rect, turns) for rect in rects]


def blocked_intervals(rects, temple_index):
    turned = oriented(rects, temple_index)
    minx, miny, maxx, maxy, _ = turned[temple_index]
    center_x = Fraction(minx + maxx, 2)
    center_y = Fraction(miny + maxy, 2)
    width = maxx - minx
    height = maxy - miny
    bound = Fraction(height, 2 * width)
    intervals = []
    for index, rect in enumerate(turned):
        if index == temple_index:
            continue
        x1, y1, x2, y2 = rect[0], rect[1], rect[2], rect[3]
        far = Fraction(x2) - center_x
        if far <= 0:
            continue
        near = Fraction(x1) - center_x
        if near < 0:
            near = Fraction(0)
        low_y = Fraction(y1) - center_y
        high_y = Fraction(y2) - center_y
        if low_y > 0:
            lower = low_y / far
        else:
            lower = None if near <= 0 else low_y / near
        if high_y > 0:
            upper = None if near <= 0 else high_y / near
        else:
            upper = high_y / far
        lower = -bound if lower is None else max(lower, -bound)
        upper = bound if upper is None else min(upper, bound)
        if lower < upper:
            intervals.append((lower, upper))
    intervals.sort()
    return bound, intervals


def per_rect_escape(rects, temple_index):
    bound, intervals = blocked_intervals(rects, temple_index)
    current = -bound
    for lower, upper in intervals:
        if upper <= current:
            continue
        if lower > current:
            return True
        current = upper
        if current >= bound:
            return False
    return current < bound


def ray_hits_rect(rect, slope, center_x, center_y):
    x1, y1, x2, y2 = rect[0], rect[1], rect[2], rect[3]
    far = Fraction(x2) - center_x
    if far <= 0:
        return False
    near = Fraction(x1) - center_x
    if near < 0:
        near = Fraction(0)
    low_y = Fraction(y1) - center_y
    high_y = Fraction(y2) - center_y
    if slope > 0:
        return high_y > 0 and slope * far >= low_y and slope * near <= high_y
    if slope < 0:
        return slope * near >= low_y and slope * far <= high_y
    return low_y <= 0 <= high_y


def brute_escape(rects, temple_index):
    turned = oriented(rects, temple_index)
    minx, miny, maxx, maxy, _ = turned[temple_index]
    center_x = Fraction(minx + maxx, 2)
    center_y = Fraction(miny + maxy, 2)
    width = maxx - minx
    height = maxy - miny
    bound = Fraction(height, 2 * width)
    candidates = {-bound, bound}
    for index, rect in enumerate(turned):
        if index == temple_index:
            continue
        for corner_x in (rect[0], rect[2]):
            delta_x = Fraction(corner_x) - center_x
            if delta_x <= 0:
                continue
            for corner_y in (rect[1], rect[3]):
                slope = (Fraction(corner_y) - center_y) / delta_x
                if -bound < slope < bound:
                    candidates.add(slope)
    slopes = sorted(candidates)
    for index in range(len(slopes) - 1):
        middle = (slopes[index] + slopes[index + 1]) / 2
        blocked = False
        for other, rect in enumerate(turned):
            if other == temple_index:
                continue
            if ray_hits_rect(rect, middle, center_x, center_y):
                blocked = True
                break
        if not blocked:
            return True
    return False


def oracle(cases):
    lines = []
    for rects in cases:
        escaped = []
        for index in range(len(rects)):
            if per_rect_escape(rects, index):
                escaped.append(index + 1)
        if escaped:
            lines.extend(str(value) for value in escaped)
        else:
            lines.append('NONE')
    return '\n'.join(lines) + '\n'


def text_of(cases):
    parts = [str(len(cases))]
    for index, rects in enumerate(cases):
        if index > 0:
            parts.append('')
        parts.append(str(len(rects)))
        for minx, miny, maxx, maxy, facing in rects:
            parts.append('%d %d %d %d %s' % (
                minx, maxy, maxx, miny, 'ENWS'[facing]))
    return '\n'.join(parts) + '\n'


def write_case(name, cases):
    input_text = text_of(cases)
    (ROOT / 'in' / (name + '.txt')).write_text(input_text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(cases))


def make_case(rng, size, grid, domain=8000, margin=4):
    cells = [(row, col) for row in range(grid) for col in range(grid)]
    rng.shuffle(cells)
    step = domain // grid
    rects = []
    for index in range(size):
        row, col = cells[index]
        base_x = row * step
        base_y = col * step
        width = rng.randint(1, step - 2 * margin)
        height = rng.randint(1, step - 2 * margin)
        x1 = base_x + rng.randint(margin, step - margin - width)
        y1 = base_y + rng.randint(margin, step - margin - height)
        rects.append((x1, y1, x1 + width, y1 + height,
                      FACING[rng.choice('ENWS')]))
    return rects


SAMPLE = [
    (1, 1, 4, 7, 0),
    (3, 8, 11, 9, 3),
    (6, 4, 10, 7, 1),
    (8, 1, 10, 3, 1),
    (11, 1, 13, 4, 0),
    (14, 7, 20, 8, 2),
]

assert oracle([SAMPLE]) == '1\n2\n5\n6\n'
assert per_rect_escape([(0, 0, 10, 10, 0)], 0) is True
assert brute_escape([(0, 0, 10, 10, 0)], 0) is True

check_rng = random.Random(7)
for trial in range(60):
    sample = make_case(check_rng, 12, 6, domain=240, margin=4)
    for index in range(len(sample)):
        assert per_rect_escape(sample, index) == brute_escape(
            sample, index), (trial, index)


def build():
    edges = [
        [(2, 2, 3, 3, 0)],
        [(0, 0, 1, 1, 1)],
        [(0, 0, 8000, 1, 2), (0, 3, 8000, 4, 3)],
        [(10, 10, 11, 11, 0), (20, 10, 21, 11, 0),
         (30, 10, 31, 11, 0)],
        [(100, 100, 200, 200, 0), (110, 120, 130, 140, 1)],
        [(0, 0, 20, 8000, 0), (30, 0, 50, 8000, 2)],
    ]
    assert oracle([edges[-1]]) == 'NONE\n'
    write_case('2_edges', edges)

    wide_rng = random.Random(11)
    write_case('3_wide', [make_case(wide_rng, 1000, 33)])

    random_rng = random.Random(2026)
    write_case('4_random', [make_case(random_rng, 80, 12)
                            for _ in range(12)])

    io_rng = random.Random(99)
    write_case('5_io', [make_case(io_rng, 60, 9)
                        for _ in range(200)])


def worked_example():
    bound, intervals = blocked_intervals(SAMPLE, 0)
    print('wedge (-%s, %s)' % (bound, bound))
    for lower, upper in intervals:
        print('%s %s %.4f %.4f' % (lower, upper, float(lower), float(upper)))


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write_case('1_sample', [SAMPLE])
build()
worked_example()
