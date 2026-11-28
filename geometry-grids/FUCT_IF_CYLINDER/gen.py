#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

PI_VALUE = 3.14
HEIGHT_MESSAGE = "the height of cylinder must be greater than 0"
RADIUS_MESSAGE = "the radius of cylinder must be greater than 0"

SAMPLE_INPUT = """5
1 1
8 -2
4 10
0 7
12 18
"""

SAMPLE_OUT = """3.14 12.56
the height of cylinder must be greater than 0
502.40 351.68
the radius of cylinder must be greater than 0
8138.88 2260.80
"""


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    cursor = 1
    for _ in range(case_count):
        radius = int(tokens[cursor])
        height = int(tokens[cursor + 1])
        cursor += 2
        if radius <= 0:
            answers.append(RADIUS_MESSAGE)
        elif height <= 0:
            answers.append(HEIGHT_MESSAGE)
        else:
            value = float(radius)
            tall = float(height)
            volume = PI_VALUE * value * value * tall
            surface = 2.0 * PI_VALUE * value * (value + tall)
            answers.append(f"{volume:.2f} {surface:.2f}")
    return "\n".join(answers) + "\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{radius} {height}\n" for radius, height in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1 2\n") == "6.28 18.84\n"
assert oracle("1\n10 10\n") == "3140.00 1256.00\n"
assert oracle("1\n0 -3\n") == RADIUS_MESSAGE + "\n"


def build():
    write("2_edges", [(0, 1), (-1, 1), (1, 0), (1, -2), (1, 1), (2, 3),
                      (100000, 100000), (5, 1000000)])
    rng = random.Random(70041)
    write("3_wide", [(rng.randint(1, 10**6), rng.randint(1, 10**6))
                     for _ in range(1000)])
    write("4_random", [(rng.randint(-50, 10000), rng.randint(-50, 10000))
                       for _ in range(1000)])
    write("5_io", [(rng.randint(1, 100000), rng.randint(1, 100000))
                   for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
