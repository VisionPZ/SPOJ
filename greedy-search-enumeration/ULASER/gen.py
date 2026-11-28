#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    box_count = tokens[0]
    start_x, start_y = tokens[1], tokens[2]
    boxes = []
    cursor = 3
    for _ in range(box_count):
        first_x, first_y, second_x, second_y = tokens[cursor:cursor + 4]
        cursor += 4
        boxes.append((min(first_x, second_x), min(first_y, second_y),
                      max(first_x, second_x), max(first_y, second_y)))
    occupied = set()
    for lower_x, lower_y, upper_x, upper_y in boxes:
        for cell_x in range(lower_x, upper_x):
            for cell_y in range(lower_y, upper_y):
                occupied.add((cell_x, cell_y))

    def cell(point_x, point_y, step_x, step_y):
        return (point_x + min(0, step_x), point_y + min(0, step_y))

    visited = {(start_x, start_y)}
    segments = []
    current_x, current_y = start_x, start_y
    step_x, step_y = 1, -1
    time_value = 0
    for _ in range(400000):
        forward = cell(current_x, current_y, step_x, step_y)
        below = cell(current_x, current_y, -step_x, step_y)
        aside = cell(current_x, current_y, step_x, -step_y)
        if not (forward in occupied and below in occupied and aside in occupied):
            if below in occupied and aside not in occupied:
                step_x = -step_x
            elif aside in occupied and below not in occupied:
                step_y = -step_y
            else:
                return (f"{time_value:.1f}\n"
                        f"{float(current_x):.1f} {float(current_y):.1f}\n")
        travelled = cell(current_x, current_y, step_x, step_y)
        orientation = 0 if step_x == step_y else 1
        for old_x, old_y, old_orientation in segments:
            if (old_x, old_y) == travelled and old_orientation != orientation:
                return (f"{time_value + 0.5:.1f}\n"
                        f"{travelled[0] + 0.5:.1f} {travelled[1] + 0.5:.1f}\n")
        segments.append((travelled[0], travelled[1], orientation))
        next_x = current_x + step_x
        next_y = current_y + step_y
        next_time = time_value + 1
        if (next_x, next_y) == (start_x, start_y):
            return f"{next_time:.1f}\nBroken equipment\n"
        if (next_x, next_y) in visited:
            return (f"{next_time:.1f}\n"
                    f"{float(next_x):.1f} {float(next_y):.1f}\n")
        visited.add((next_x, next_y))
        current_x, current_y = next_x, next_y
        time_value = next_time
    return "Time limit exceeded\n"


SAMPLE = """7
0 4
-1 5 1 -1
0 -2 4 2
0 -4 1 2
2 -4 5 -1
5 2 7 4
3 -5 4 -4
0 -6 3 -4
"""
SAMPLE_OUT = "12.0\n0.0 0.0\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SAMPLE.replace("0 4\n", "0 3\n", 1)) == "12.0\n0.0 -1.0\n"
assert oracle(SAMPLE.replace("0 4\n", "0 1\n", 1)) == "5.0\n5.0 -4.0\n"
assert oracle(SAMPLE.replace("0 4\n", "0 0\n", 1)) == "8.0\nBroken equipment\n"
assert oracle("1\n0 0\n0 0 3 3\n").endswith("\n")


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(boxes, laser):
    lines = [str(len(boxes)), f"{laser[0]} {laser[1]}"]
    lines.extend(f"{x1} {y1} {x2} {y2}" for x1, y1, x2, y2 in boxes)
    return "\n".join(lines) + "\n"


def build():
    write("2_edges", make_case([(0, 0, 3, 3)], (1, 1)))
    write("2_edges_b", make_case([(-4, -4, 4, 4)], (-2, 2)))
    write("3_wide", make_case([(2998, 2998, 3000, 3000)], (2999, 2999)))
    rng = random.Random(20261126)
    for index in range(1, 4):
        boxes = []
        for _ in range(rng.randint(1, 6)):
            lower_x = rng.randint(-12, 10)
            lower_y = rng.randint(-12, 10)
            upper_x = lower_x + rng.randint(2, 8)
            upper_y = lower_y + rng.randint(2, 8)
            boxes.append((lower_x, lower_y, upper_x, upper_y))
        origin = boxes[0]
        laser = (rng.randint(origin[0] + 1, origin[2] - 1),
                 rng.randint(origin[1] + 1, origin[3] - 1))
        write(f"4_random_{index}", make_case(boxes, laser))
    write("5_io", make_case([(0, 0, 16, 16)], (8, 8)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
