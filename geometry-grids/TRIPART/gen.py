#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = {}


def angle_key(sides):
    left, middle, right = sorted(sides)
    result = []
    for first, second, opposite in ((left, middle, right),
                                    (middle, right, left),
                                    (right, left, middle)):
        cosine = (first * first + second * second - opposite * opposite) / (2 * first * second)
        result.append(math.acos(max(-1.0, min(1.0, cosine))))
    result.sort()
    return result


def same_shape(first, second, eps=1e-8):
    return all(abs(left - right) < eps for left, right in zip(first, second))


def count_styles(side1, side2, side3):
    key = (side1, side2, side3)
    if key in CACHE:
        return CACHE[key]
    start = sorted((float(side1), float(side2), float(side3)))
    representatives = [angle_key(start)]
    work = [start]
    while work:
        left, middle, right = sorted(work.pop())
        across = (left * left + right * right - middle * middle) / (2 * right)
        height = math.sqrt(max(0.0, left * left - across * across))
        median = math.hypot(across - right / 2, height)
        for child in ((left, right / 2, median), (middle, right / 2, median)):
            angles = angle_key(child)
            if not any(same_shape(angles, representative) for representative in representatives):
                representatives.append(angles)
                work.append(child)
    answer = len(representatives)
    CACHE[key] = answer
    return answer


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        side1 = int(tokens[cursor]); cursor += 1
        side2 = int(tokens[cursor]); cursor += 1
        side3 = int(tokens[cursor]); cursor += 1
        answers.append(str(count_styles(side1, side2, side3)))
    return "\n".join(answers) + "\n"


def write(name, triples):
    input_text = str(len(triples)) + "\n" + "".join(
        f"{side1} {side2} {side3}\n" for side1, side2, side3 in triples)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [(3, 4, 5), (12, 84, 90)]
assert oracle("2\n3 4 5\n12 84 90\n") == "3\n41\n"
assert oracle("1\n1 1 1\n") == "3\n"
assert oracle("1\n2 98 99\n") == "334\n"
assert oracle("1\n13 14 15\n") == "4\n"


def random_triangle(rng):
    while True:
        sides = sorted(rng.randint(1, 99) for _ in range(3))
        if sides[0] + sides[1] > sides[2]:
            return tuple(sides)


def build():
    write("2_edges", [(1, 1, 1), (99, 99, 99), (1, 2, 2), (2, 2, 3),
                      (1, 99, 99), (50, 50, 99), (2, 98, 99), (3, 4, 5),
                      (12, 84, 90), (13, 14, 15)])
    write("3_wide", [(2, 98, 99), (1, 99, 99), (99, 99, 99), (50, 50, 99),
                     (98, 98, 99), (1, 2, 2)] * 5 + [(2, 98, 99), (1, 99, 99),
                     (99, 99, 99), (50, 50, 99)])
    random.seed(2026)
    write("4_random", [random_triangle(random) for _ in range(34)])
    write("5_io", [(2, 98, 99)] * 34)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
