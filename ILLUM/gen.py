#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def cube_box(vertices):
    columns = list(zip(*vertices))
    return [(min(column), max(column)) for column in columns]


def interval_shadow(source, target, bulb):
    total = 0.0
    for axis in range(3):
        for side in (0, 1):
            plane = target[axis][side]
            outward = -1.0 if side == 0 else 1.0
            if (bulb[axis] - plane) * outward <= 0:
                continue
            bulb_axis = bulb[axis]
            ranges = {}
            for source_coordinate in source[axis]:
                scale = (plane - bulb_axis) / (source_coordinate - bulb_axis)
                if scale <= 1:
                    continue
                for other_axis in range(3):
                    if other_axis == axis:
                        continue
                    bulb_other = bulb[other_axis]
                    values = [bulb_other + scale * (value - bulb_other)
                              for value in source[other_axis]]
                    low, high = min(values), max(values)
                    if other_axis not in ranges:
                        ranges[other_axis] = [low, high]
                    else:
                        ranges[other_axis][0] = min(ranges[other_axis][0], low)
                        ranges[other_axis][1] = max(ranges[other_axis][1], high)
            if len(ranges) < 2:
                continue
            face_area = 1.0
            for other_axis, (low, high) in ranges.items():
                low = max(low, target[other_axis][0])
                high = min(high, target[other_axis][1])
                if high <= low:
                    face_area = 0.0
                    break
                face_area *= high - low
            total += face_area
    return total


def oracle(text):
    numbers = [float(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor + 27 <= len(numbers):
        bulb = tuple(numbers[cursor:cursor + 3])
        cursor += 3
        first_vertices = [tuple(numbers[cursor + 3 * index:cursor + 3 * index + 3])
                          for index in range(4)]
        cursor += 12
        second_vertices = [tuple(numbers[cursor + 3 * index:cursor + 3 * index + 3])
                           for index in range(4)]
        cursor += 12
        first_box = cube_box(first_vertices)
        second_box = cube_box(second_vertices)
        on_first = interval_shadow(second_box, first_box, bulb)
        on_second = interval_shadow(first_box, second_box, bulb)
        if max(on_first, on_second) < 1e-3:
            answers.append('-1')
        elif on_second >= on_first:
            answers.append(f'2 {on_second:.3f}')
        else:
            answers.append(f'1 {on_first:.3f}')
    return '\n'.join(answers) + '\n'


SAMPLE = """-1.00000 1.00000 1.00000
0.00000 0.00000 0.00000
2.00000 0.00000 0.00000
0.00000 2.00000 0.00000
0.00000 0.00000 2.00000
5.00000 0.00000 0.00000
7.00000 0.00000 0.00000
5.00000 2.00000 0.00000
5.00000 0.00000 2.00000
0.00000 0.00000 0.00000
1.00000 1.00000 1.00000
2.00000 1.00000 1.00000
1.00000 2.00000 1.00000
1.00000 1.00000 2.00000
-1.00000 -1.00000 -1.00000
-1.00000 -2.00000 -1.00000
-2.00000 -1.00000 -1.00000
-1.00000 -1.00000 -2.00000
"""
SAMPLE_OUT = """2 4.000
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("-2.0 0.5 0.5\n0 0 0\n2 0 0\n0 2 0\n0 0 2\n5 0 0\n7 0 0\n5 2 0\n5 0 2\n") == "2 4.000\n"
assert oracle("9.0 0.5 0.5\n0 0 0\n2 0 0\n0 2 0\n0 0 2\n5 0 0\n7 0 0\n5 2 0\n5 0 2\n") == "1 4.000\n"


def cube_lines(box):
    (x0, x1), (y0, y1), (z0, z1) = box
    return [(x0, y0, z0), (x1, y0, z0), (x0, y1, z0), (x0, y0, z1)]


def format_case(bulb, first_box, second_box):
    lines = []
    for point in [bulb] + cube_lines(first_box) + cube_lines(second_box):
        lines.append(' '.join(f'{value:.5f}' for value in point))
    return '\n'.join(lines) + '\n'


def write(name, cases):
    text = ''.join(format_case(*case) for case in cases)
    (ROOT / 'in' / (name + '.txt')).write_text(text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    base = [(0.0, 2.0), (0.0, 2.0), (0.0, 2.0)]
    far = [(5.0, 7.0), (0.0, 2.0), (0.0, 2.0)]
    tiny = [(5.0, 6.0), (0.5, 1.5), (0.5, 1.5)]
    write('2_edges', [((-1.0, 1.0, 1.0), base, far),
                      ((-1.0, 1.0, 1.0), base, tiny),
                      ((9.0, 1.0, 1.0), base, far),
                      ((-1.0, 3.5, 3.5), base, far)])
    wide_source = [(0.0, 100.0), (0.0, 100.0), (0.0, 100.0)]
    wide_target = [(200.0, 300.0), (0.0, 100.0), (0.0, 100.0)]
    write('3_wide', [((-50.0, 50.0, 50.0), wide_source, wide_target)])
    random_cases = []
    for _ in range(20):
        first_x = rng.uniform(0, 5)
        first_size = rng.uniform(1, 4)
        gap = rng.uniform(1, 5)
        second_size = rng.uniform(1, 4)
        source = [(first_x, first_x + first_size), (0.0, 2.0), (0.0, 2.0)]
        target = [(first_x + first_size + gap, first_x + first_size + gap + second_size),
                  (0.0, 2.0), (0.0, 2.0)]
        bulb = (first_x - rng.uniform(1, 4), 1.0, 1.0)
        random_cases.append((bulb, source, target))
    write('4_random', random_cases)
    io_cases = []
    for index in range(60):
        source = [(0.0, 2.0), (0.0, 2.0), (0.0, 2.0)]
        target = [(4.0 + index % 3, 7.0 + index % 3), (0.0, 2.0), (0.0, 2.0)]
        io_cases.append(((-1.0, 1.0, 1.0), source, target))
    write('5_io', io_cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE)
(ROOT / 'out' / '1_sample.out').write_text(oracle(SAMPLE))
build()
