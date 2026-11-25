#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def vectors(length):
    found = set()
    for dx in range(-length, length + 1):
        remainder = length * length - dx * dx
        if remainder < 0:
            continue
        dy = int(math.isqrt(remainder))
        if dy * dy == remainder:
            found.add((dx, dy))
            found.add((dx, -dy))
    for dx, dy in list(found):
        found.add((dy, dx))
    return sorted(found)


def polygon_area(vector_list):
    ordered = sorted(vector_list, key=lambda value: math.atan2(value[1], value[0]))
    twice = 0
    for first in range(len(ordered)):
        for second in range(first + 1, len(ordered)):
            twice += ordered[first][0] * ordered[second][1] - ordered[first][1] * ordered[second][0]
    return twice


def solve_lengths(lengths):
    options = [vectors(length) for length in lengths]
    count = len(lengths)
    remaining = [0] * (count + 1)
    for index in range(count - 1, -1, -1):
        remaining[index] = remaining[index + 1] + lengths[index]
    best = -1
    choice = [None] * count

    def walk(position, sum_x, sum_y):
        nonlocal best
        if position == count:
            if sum_x == 0 and sum_y == 0:
                twice = polygon_area(choice)
                if twice > best:
                    best = twice
            return
        for vx, vy in options[position]:
            new_x = sum_x + vx
            new_y = sum_y + vy
            left = remaining[position + 1]
            if new_x * new_x + new_y * new_y > left * left:
                continue
            choice[position] = (vx, vy)
            walk(position + 1, new_x, new_y)

    walk(0, 0, 0)
    return best // 2 if best > 0 else -1


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        count = tokens[cursor]
        cursor += 1
        if count == 0:
            break
        lengths = tokens[cursor:cursor + count]
        cursor += count
        answers.append(str(solve_lengths(lengths)))
    return "\n".join(answers) + "\n"


SAMPLE_IN = """3
3 4 5
5
1 2 5 5 5
6
195 221 255 260 265 290
6
130 145 169 185 195 265
3
1 1 2
6
3 3 3 3 3 3
0
"""
SAMPLE_OUT = """6
19
158253
-1
-1
18
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("3\n3 4 5\n0\n") == "6\n"
assert oracle("5\n1 2 5 5 5\n0\n") == "19\n"
assert oracle("3\n1 1 2\n0\n") == "-1\n"
assert oracle("6\n3 3 3 3 3 3\n0\n") == "18\n"
assert vectors(5) == [(-5, 0), (-4, -3), (-4, 3), (-3, -4), (-3, 4), (0, -5), (0, 5),
                      (3, -4), (3, 4), (4, -3), (4, 3), (5, 0)]


def write(name, datasets):
    lines = []
    for lengths in datasets:
        lines.append(str(len(lengths)))
        lines.append(" ".join(str(value) for value in lengths))
    lines.append("0")
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [[3, 4, 5], [1, 1, 2], [3, 3, 3, 3, 3, 3], [1, 2, 2], [5, 5, 5, 5]])
    rng = random.Random(20261126)
    wide = []
    for _ in range(3):
        wide.append([rng.randint(150, 300) for _ in range(6)])
    write("3_wide", wide)
    random_sets = []
    for _ in range(20):
        count = rng.randint(3, 6)
        random_sets.append([rng.randint(1, 60) for _ in range(count)])
    write("4_random", random_sets)
    io_sets = [[rng.randint(1, 20) for _ in range(3)] for _ in range(100)]
    write("5_io", io_sets)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
