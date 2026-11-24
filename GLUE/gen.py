#!/usr/bin/env python3
import math
import random
from functools import cmp_to_key
from math import gcd
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_rectangles(points):
    """Enumerate boxes from every dab-pair direction and count distinct regions."""
    from fractions import Fraction

    directions = set()
    for i in range(len(points)):
        for j in range(i + 1, len(points)):
            dx = points[j][0] - points[i][0]
            dy = points[j][1] - points[i][1]
            divisor = gcd(abs(dx), abs(dy))
            if divisor == 0:
                continue
            dx //= divisor
            dy //= divisor
            if dx < 0 or (dx == 0 and dy < 0):
                dx, dy = -dx, -dy
            directions.add((dx, dy))

    regions = set()
    for axis in directions:
        other = (-axis[1], axis[0])
        first = [x * axis[0] + y * axis[1] for x, y in points]
        second = [x * other[0] + y * other[1] for x, y in points]
        lowFirst, highFirst = min(first), max(first)
        lowSecond, highSecond = min(second), max(second)
        if lowFirst == highFirst or lowSecond == highSecond:
            continue
        if sum(t == lowFirst for t in first) < 2 or sum(t == highFirst for t in first) < 2:
            continue
        if sum(t == lowSecond for t in second) < 2 or sum(t == highSecond for t in second) < 2:
            continue
        det = axis[0] * other[1] - axis[1] * other[0]

        def corner(along, across):
            x = Fraction(along * other[1] - across * axis[1], det)
            y = Fraction(across * axis[0] - along * other[0], det)
            return (x, y)

        regions.add(tuple(sorted((
            corner(lowFirst, lowSecond), corner(highFirst, lowSecond),
            corner(highFirst, highSecond), corner(lowFirst, highSecond)))))
    return len(regions)


def graham_hull(points):
    """Graham scan: sort by polar angle around the lowest dab, then keep left turns."""
    distinct = sorted(set(points))
    if len(distinct) <= 2:
        return distinct
    pivot = min(distinct, key=lambda point: (point[1], point[0]))

    def by_angle(left, right):
        turn = ((left[0] - pivot[0]) * (right[1] - pivot[1])
                - (left[1] - pivot[1]) * (right[0] - pivot[0]))
        if turn != 0:
            return -1 if turn > 0 else 1
        leftDistance = (left[0] - pivot[0]) ** 2 + (left[1] - pivot[1]) ** 2
        rightDistance = (right[0] - pivot[0]) ** 2 + (right[1] - pivot[1]) ** 2
        if leftDistance != rightDistance:
            return -1 if leftDistance < rightDistance else 1
        return 0

    rest = [point for point in distinct if point != pivot]
    rest.sort(key=cmp_to_key(by_angle))
    stack = [pivot]
    for point in rest:
        while len(stack) >= 2:
            first, second = stack[-2], stack[-1]
            turn = ((second[0] - first[0]) * (point[1] - first[1])
                    - (second[1] - first[1]) * (point[0] - first[0]))
            if turn > 0:
                break
            stack.pop()
        stack.append(point)
    return stack


def slope_oracle(points):
    """Count perpendicular hull-edge directions that occur on both opposite sides."""
    hull = graham_hull(points)
    if len(hull) < 3:
        return 0
    frequency = {}
    for i in range(len(hull)):
        first, second = hull[i], hull[(i + 1) % len(hull)]
        dx = second[0] - first[0]
        dy = second[1] - first[1]
        divisor = gcd(abs(dx), abs(dy))
        dx //= divisor
        dy //= divisor
        if dx < 0 or (dx == 0 and dy < 0):
            dx, dy = -dx, -dy
        frequency[(dx, dy)] = frequency.get((dx, dy), 0) + 1
    answer = 0
    for direction, occurrences in frequency.items():
        if occurrences < 2:
            continue
        across = (-direction[1], direction[0])
        if across[0] < 0 or (across[0] == 0 and across[1] < 0):
            across = (-across[0], -across[1])
        if frequency.get(across, 0) >= 2 and direction < across:
            answer += 1
    return answer


def render(cases, oracle):
    input_text = str(len(cases)) + "\n"
    outputs = []
    for points in cases:
        input_text += str(len(points)) + "\n"
        for x, y in points:
            input_text += f"{x} {y}\n"
        outputs.append(str(oracle(points)))
    return input_text, "\n".join(outputs) + "\n"


def write(name, cases, oracle):
    input_text, output_text = render(cases, oracle)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


SAMPLE = [(1, 0), (1, 4), (0, 3), (5, 4), (5, 0), (6, 1), (6, 3), (0, 1)]
assert brute_rectangles(SAMPLE) == 2
assert slope_oracle(SAMPLE) == 2
assert brute_rectangles([(0, 0), (4, 0), (4, 3), (0, 3)]) == 1
assert brute_rectangles([(0, 0), (1, 0), (2, 0), (3, 0)]) == 0
assert brute_rectangles([(0, 0), (2, 0), (0, 2), (2, 2)]) == 1

random.seed(2026)
for _ in range(300):
    count = random.randint(3, 9)
    sample = random.sample([(x, y) for x in range(-5, 6) for y in range(-5, 6)], count)
    assert brute_rectangles(sample) == slope_oracle(sample), sample


def worked_example():
    hull = graham_hull(SAMPLE)
    normals = set()
    for i in range(len(hull)):
        first, second = hull[i], hull[(i + 1) % len(hull)]
        dx = second[0] - first[0]
        dy = second[1] - first[1]
        divisor = gcd(abs(dx), abs(dy))
        normals.add((dy // divisor, -dx // divisor))
    normals = sorted(normals)
    lines = [f"sample hull vertices: {len(hull)}"]
    passed = 0
    for normal in normals:
        current = normal
        turns = []
        for _ in range(4):
            turns.append(current)
            current = (-current[1], current[0])
        good = all(turn in normals for turn in turns)
        passed += good
        lines.append(f"normal {normal} passes {good}")
    lines.append(f"valid orientations {passed}")
    lines.append(f"answer {passed // 4}")
    return "\n".join(lines)


assert worked_example().endswith("answer 2")


def edges():
    return [
        [(0, 0)],
        [(0, 0), (3, 4)],
        [(0, 0), (1, 0), (2, 0)],
        [(0, 0), (4, 0), (4, 3), (0, 3)],
        [(-2, -1), (-2, 2), (3, 2), (3, -1), (0, 0)],
        [(0, 0), (2, 0), (4, 0), (0, 3), (0, 6)],
        [(0, 0), (2, 2), (0, 4), (-2, 2)],
        [(0, 0), (4, 0), (4, 4), (0, 4), (2, 0), (2, 4)],
        [(0, 0), (0, 0), (4, 0), (4, 4), (0, 4)],
        [(0, 0), (1, 2), (2, 4), (3, 6)],
    ]


def wide():
    circle = []
    for i in range(10000):
        angle = 2 * 3.141592653589793 * i / 10000
        circle.append((round(15000 * math.cos(angle)),
                       round(15000 * math.sin(angle))))
    circle = list(dict.fromkeys(circle))
    square = []
    for i in range(2500):
        square.append((-15000 + i * 12, -15000))
        square.append((15000, -15000 + i * 12))
        square.append((15000 - i * 12, 15000))
        square.append((-15000, 15000 - i * 12))
    grid = [(x * 30, y * 30) for x in range(-50, 50) for y in range(-50, 50)]
    tilted = []
    for i in range(2500):
        tilted.append((i * 6 - 7500, i * 6 - 7500))
        tilted.append((i * 6 - 7500, 7500 - i * 6))
        tilted.append((7500 - i * 6, 7500 - i * 6))
        tilted.append((7500 - i * 6, i * 6 - 7500))
    return [circle, square, grid, tilted]


def random_case(count, generator):
    seen = set()
    while len(seen) < count:
        seen.add(generator())
    return list(seen)


def build():
    write("2_edges", edges(), brute_rectangles)
    write("3_wide", wide(), slope_oracle)
    random.seed(142)
    broad = [
        random_case(10000, lambda: (random.randint(-15000, 15000),
                                    random.randint(-15000, 15000)))
        for _ in range(3)
    ]
    broad.append(random_case(9000, lambda: (random.randint(-15000, 15000),
                                            random.randint(1500, 15000))))
    write("4_random", broad, slope_oracle)
    io_cases = []
    for i in range(20000):
        offset = i % 17
        io_cases.append([(offset, 0), (offset + 40, 0),
                         (offset + 40, 30), (offset, 30)])
    write("5_io", io_cases, brute_rectangles)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE], brute_rectangles)
build()
