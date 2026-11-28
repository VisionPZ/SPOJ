#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

EDGE_MESSAGE = "the length of triangular's edge must be greater than 0"
SHAPE_MESSAGE = "three numbers a and b and c cannot make a triangular"

SAMPLE_INPUT = """7
0 5 -2
2 3 4
9 1 10
3 6 5
-9 2 4
8 4 1
15 27 20
"""

SAMPLE_OUT = """the length of triangular's edge must be greater than 0
9 2.905
three numbers a and b and c cannot make a triangular
14 7.483
the length of triangular's edge must be greater than 0
three numbers a and b and c cannot make a triangular
62 147.729
"""


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        first = int(tokens[cursor])
        second = int(tokens[cursor + 1])
        third = int(tokens[cursor + 2])
        cursor += 3
        if first <= 0 or second <= 0 or third <= 0:
            answers.append(EDGE_MESSAGE)
        elif first + second <= third or first + third <= second or second + third <= first:
            answers.append(SHAPE_MESSAGE)
        else:
            perimeter = first + second + third
            half = perimeter / 2.0
            area = math.sqrt(half * (half - first) * (half - second) * (half - third))
            answers.append(f"{perimeter} {area:.3f}")
    return "\n".join(answers) + "\n"


def write(name, triples):
    input_text = str(len(triples)) + "\n" + "".join(
        f"{first} {second} {third}\n" for first, second, third in triples)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1 1 1\n") == "3 0.433\n"
assert oracle("1\n2 2 3\n") == "7 1.984\n"
assert oracle("1\n-1 2 3\n") == EDGE_MESSAGE + "\n"


def build():
    write("2_edges", [(0, 1, 2), (-1, 1, 1), (1, -2, 3), (1, 1, -3),
                      (1, 1, 1), (1, 1, 2), (1, 2, 3), (2, 2, 3),
                      (3, 4, 5), (100000, 100000, 1), (5, 5, 9)])
    rng = random.Random(31107)
    write("3_wide", [(rng.randint(1, 10**7), rng.randint(1, 10**7),
                      rng.randint(1, 10**7)) for _ in range(1000)])
    write("4_random", [(rng.randint(-50, 1000), rng.randint(-50, 1000),
                        rng.randint(-50, 1000)) for _ in range(1000)])
    write("5_io", [(rng.randint(-1000000, 1000000), rng.randint(1, 1000000),
                    rng.randint(1, 1000000)) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
