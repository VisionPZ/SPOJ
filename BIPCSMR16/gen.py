#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2\n1 2 3\n1 12 3\n"
SAMPLE_OUTPUT = "2\n4\n"


def best_teams(groups):
    low = 0
    high = sum(groups) // 3
    while low < high:
        middle = (low + high + 1) // 2
        capacity = sum(min(value, 2 * middle) for value in groups)
        if capacity >= 3 * middle:
            low = middle
        else:
            high = middle - 1
    return low


def oracle(text):
    numbers = [int(token) for token in text.split()]
    case_count = numbers[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        groups = numbers[cursor:cursor + 3]
        cursor += 3
        answers.append(str(best_teams(groups)))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1 1 100\n") == "2\n"
assert oracle("1\n2 2 2\n") == "2\n"
assert oracle("1\n1 12 3\n") == "4\n"
assert oracle("1\n2000000000 2000000000 2000000000\n") == "2000000000\n"
for check_first in range(1, 9):
    for check_second in range(1, 9):
        for check_third in range(1, 9):
            group = [check_first, check_second, check_third]
            brute = 0
            while sum(min(value, 2 * (brute + 1)) for value in group) >= 3 * (brute + 1):
                brute += 1
            assert best_teams(group) == brute


def write(name, triples):
    lines = [str(len(triples))]
    lines.extend(f"{first} {second} {third}"
                 for first, second, third in triples)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [(1, 2, 3), (1, 12, 3)])
write("2_edges", [(1, 1, 1), (1, 1, 100), (1, 2, 100),
                  (100, 100, 1), (2000000000, 1, 1)])
write("3_wide", [(2000000000, 2000000000, 2000000000),
                 (2, 1000000000, 1000000000),
                 (999999999, 999999999, 999999999)])
random.seed(2026)
write("4_random", [(random.randint(1, 2000000000),
                    random.randint(1, 2000000000),
                    random.randint(1, 2000000000)) for _ in range(1000)])
write("5_io", [(random.choice([1, 2, 3, 1000000000, 2000000000]),
                random.choice([1, 2, 3, 1000000000, 2000000000]),
                random.choice([1, 2, 3, 1000000000, 2000000000]))
               for _ in range(10000)])
