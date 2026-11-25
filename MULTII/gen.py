#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ORACLE_STEPS = 200000


def oracle(text):
    tokens = text.split()
    scan = 0
    case_number = 0
    lines = []
    while scan < len(tokens):
        divisor = int(tokens[scan]); scan += 1
        forbidden_count = int(tokens[scan]); scan += 1
        forbidden = {int(value) for value in tokens[scan:scan + forbidden_count]}
        scan += forbidden_count
        case_number += 1
        answer = -1
        for multiple_index in range(1, ORACLE_STEPS + 1):
            candidate = multiple_index * divisor
            if all(int(digit) not in forbidden for digit in str(candidate)):
                answer = candidate
                break
        lines.append(f"Case {case_number}: {answer}")
    return "\n".join(lines) + "\n"


SAMPLE = """2345 3
7 8 9
100 1
0
"""
SAMPLE_OUT = """Case 1: 2345
Case 2: -1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 0\n\n") == "Case 1: 1\n"
assert oracle("7 1\n7\n") == "Case 1: 14\n"
assert oracle("2 1\n1\n") == "Case 1: 2\n"
assert str(2345).isdigit()


def write(name, cases):
    input_text = ""
    for divisor, forbidden in cases:
        input_text += f"{divisor} {len(forbidden)}\n"
        input_text += " ".join(str(value) for value in forbidden) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("1_sample", [(2345, [7, 8, 9]), (100, [0])])
    write("2_edges", [(1, []), (2, [1]), (9, [0, 1, 2, 3, 4, 5, 6, 7, 8])])
    write("3_wide", [(12, []), (9999, [0]), (10000, [1])])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(5):
        divisor = rng.randint(1, 60)
        forbidden = rng.sample(range(10), rng.randint(0, 4))
        random_cases.append((divisor, forbidden))
    write("4_random", random_cases)
    write("5_io", [(7, []), (7, [7]), (14, [0]), (25, [2]), (31, [3, 6]), (49, [1, 5])])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
