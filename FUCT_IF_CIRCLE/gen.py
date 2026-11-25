#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

RADIUS_MESSAGE = "the radius must be greater than 0"

SAMPLE_INPUT = """5
5
-2
1
0
4
"""

SAMPLE_OUT = """31.415927 78.539816
the radius must be greater than 0
6.283185 3.141593
the radius must be greater than 0
25.132741 50.265482
"""


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    for index in range(1, case_count + 1):
        radius = int(tokens[index])
        if radius <= 0:
            answers.append(RADIUS_MESSAGE)
        else:
            value = float(radius)
            circumference = 2.0 * math.pi * value
            area = math.pi * value * value
            answers.append(f"{circumference:.6f} {area:.6f}")
    return "\n".join(answers) + "\n"


def write(name, radii):
    input_text = str(len(radii)) + "\n" + "".join(f"{radius}\n" for radius in radii)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1\n") == "6.283185 3.141593\n"
assert oracle("1\n10\n") == "62.831853 314.159265\n"
assert oracle("1\n-7\n") == RADIUS_MESSAGE + "\n"


def build():
    write("2_edges", [-5, -1, 0, 1, 2, 3, 10, 100])
    rng = random.Random(60028)
    write("3_wide", [rng.randint(1, 10**7) for _ in range(1000)])
    write("4_random", [rng.randint(-100, 100000) for _ in range(1000)])
    write("5_io", [rng.randint(1, 1000000) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
