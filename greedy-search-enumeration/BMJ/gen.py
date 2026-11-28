#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    numbers = [int(value) for value in text.split()]
    answers = []
    for honey in numbers:
        if honey == 1:
            answers.append("0 0")
            continue
        ring = int((3.0 + math.sqrt(12.0 * honey - 15.0) + 1e-7) / 6.0)
        square = 3 * ring * ring
        if honey <= square - 2 * ring + 1:
            coord_x = square - 2 * ring + 1 - honey
            coord_y = ring - coord_x
        elif honey <= square - ring + 1:
            coord_x = square - 2 * ring + 1 - honey
            coord_y = ring
        elif honey <= square + 1:
            coord_x = -ring
            coord_y = square + 1 - honey
        elif honey <= square + ring + 1:
            coord_x = honey - (square + ring + 1)
            coord_y = square + 1 - honey
        elif honey <= square + 2 * ring + 1:
            coord_x = honey - (square + ring + 1)
            coord_y = -ring
        else:
            coord_x = ring
            coord_y = honey - (square + 3 * ring + 1)
        answers.append(f"{coord_x} {coord_y}")
    return "\n".join(answers) + "\n"


def spiral_map(limit):
    result = {1: (0, 0)}
    delta_x = [-1, -1, 0, 1, 1, 0]
    delta_y = [1, 0, -1, -1, 0, 1]
    number = 2
    ring = 1
    while number <= limit:
        coord_x, coord_y = ring - 1, 1
        result[number] = (coord_x, coord_y)
        number += 1
        lengths = [ring - 1] + [ring] * 5
        for segment_index in range(6):
            for _ in range(lengths[segment_index]):
                if number > limit:
                    break
                coord_x += delta_x[segment_index]
                coord_y += delta_y[segment_index]
                result[number] = (coord_x, coord_y)
                number += 1
        ring += 1
    return result


SAMPLE = """1
2
3
4
5
"""
SAMPLE_OUT = """0 0
0 1
-1 1
-1 0
0 -1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("7\n") == "1 0\n"
assert oracle("8\n") == "1 1\n"
assert oracle("19\n") == "2 0\n"
spiral = spiral_map(200)
assert all(oracle(f"{number}\n") == f"{spiral[number][0]} {spiral[number][1]}\n"
           for number in range(1, 201))


def write(name, numbers):
    input_text = "".join(str(number) + "\n" for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 2, 3, 7, 8, 19, 20, 99999])
    write("3_wide", list(range(1, 80)) + [99998, 99999])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 99999) for _ in range(300)])
    write("5_io", [rng.randint(1, 99999) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3, 4, 5])
build()
