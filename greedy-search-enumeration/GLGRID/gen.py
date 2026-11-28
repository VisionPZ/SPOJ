#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SEARCH_LIMIT = 200000


def oracle(text):
    lines = text.splitlines()
    case_count = int(lines[0])
    answers = []
    for line in lines[1:1 + case_count]:
        first_coefficient, second_coefficient, third_coefficient, value_count = map(int, line.split())
        found = []
        for value in range(SEARCH_LIMIT + 1):
            total = first_coefficient * value * value + second_coefficient * value + third_coefficient
            root = math.isqrt(total)
            if root * root == total:
                found.append(value)
                if len(found) >= value_count:
                    break
        answers.extend(str(value) for value in found)
    return "\n".join(answers) + "\n"


SAMPLE = """1
1 2 1 4
"""
SAMPLE_OUT = """0
1
2
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2 3 1 3\n") == "0\n24\n840\n"
assert oracle("1\n0 2 1 3\n") == "0\n4\n12\n"
assert oracle("1\n4 4 1 3\n") == "0\n1\n2\n"
assert oracle("1\n0 0 9 2\n") == "0\n1\n"


def encode(cases):
    lines = [str(len(cases))]
    for case in cases:
        lines.append(" ".join(str(value) for value in case))
    return "\n".join(lines) + "\n"


def write(name, cases):
    input_text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(0, 0, 1, 5), (0, 0, 2, 5), (0, 2, 1, 6),
                      (1, 2, 1, 8), (4, 4, 1, 6), (2, 3, 1, 3)])
    write("3_wide", [(4, 4, 1, 40), (0, 7, 9, 40), (9, 6, 1, 40),
                     (1, 2, 1, 40)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(10):
        first_root = rng.randint(1, 4)
        second_root = rng.randint(0, 4)
        random_cases.append((first_root * first_root, 2 * first_root * second_root,
                             second_root * second_root, 8))
    for _ in range(10):
        step = rng.randint(1, 20)
        third_coefficient = rng.randint(0, 4) ** 2
        random_cases.append((0, step, third_coefficient, 8))
    write("4_random", random_cases)
    write("5_io", [(1, 2, 1, 1000), (4, 4, 1, 1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 2, 1, 4)])
build()
