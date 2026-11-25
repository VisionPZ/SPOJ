#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for level in tokens[1:1 + case_count]:
        upright_sum = level * (level + 1) * (level + 2) // 6
        half = level // 2
        first_term = level + 1
        second_term = level + 2
        raw_sum = half * first_term * second_term
        raw_sum -= (first_term + second_term) * half * (half + 1)
        raw_sum += 4 * half * (half + 1) * (2 * half + 1) // 6
        downward_sum = raw_sum // 2
        answers.append(str(upright_sum + downward_sum))
    return "\n".join(answers) + "\n"


SAMPLE = """3
1
2
3
"""
SAMPLE_OUT = """1
5
13
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n2\n") == "5\n"
assert oracle("1\n4\n") == "27\n"
assert oracle("1\n6\n") == "78\n"
def brute_total(level):
    total = 0
    for side in range(1, level + 1):
        span = level - side + 1
        total += span * (span + 1) // 2
    side = 1
    while 2 * side <= level:
        span = level - 2 * side + 1
        total += span * (span + 1) // 2
        side += 1
    return str(total) + "\n"


assert oracle("1\n50\n") == brute_total(50)


def write(name, levels):
    input_text = str(len(levels)) + "\n" + "".join(str(level) + "\n" for level in levels)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 1, 2, 2, 1000000])
    write("3_wide", [10**6, 999999, 1, 500000, 2, 3])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 10**6) for _ in range(200)])
    write("5_io", [rng.choice([1, 2, 3, 999999, 10**6]) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3])
build()
