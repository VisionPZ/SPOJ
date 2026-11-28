#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for case_index in range(case_count):
        perimeter = tokens[1 + case_index]
        total = 0
        for longest in range((perimeter + 2) // 3, (perimeter - 1) // 2 + 1):
            lowest = max(1, perimeter - 2 * longest)
            highest = (perimeter - longest) // 2
            if highest >= lowest:
                total += highest - lowest + 1
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = """3
5
7
9
"""
SAMPLE_OUT = """1
2
3
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "0\n"
assert oracle("1\n4\n") == "0\n"
assert oracle("1\n12\n") == "3\n"
assert oracle("5\n3 5 7 9 12\n") == "1\n1\n2\n3\n3\n"

def brute(side_sum):
    count = 0
    for first in range(1, side_sum + 1):
        for second in range(first, side_sum + 1):
            third = side_sum - first - second
            if third >= second and first + second > third:
                count += 1
    return count


for perimeter in range(1, 201):
    text = f"1\n{perimeter}\n"
    assert oracle(text) == f"{brute(perimeter)}\n"


def write(name, perimeters):
    text = str(len(perimeters)) + "\n" + "\n".join(str(value) for value in perimeters) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [100000, 99999, 100000 - 1])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 100000) for _ in range(100)])
    write("5_io", [rng.randint(1, 60) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [5, 7, 9])
build()
