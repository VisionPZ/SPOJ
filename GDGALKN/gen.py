#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "1\n8\n"
SAMPLE_OUTPUT = "2\n"


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        remaining = int(tokens[cursor])
        cursor += 1
        guards = 0
        while remaining >= 3:
            remaining -= 3
            guards += 1
        answers.append(str(guards))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n3\n") == "1\n"
assert oracle("1\n5\n") == "1\n"
assert oracle("1\n6\n") == "2\n"
assert oracle("1\n100000\n") == "33333\n"


def write(name, sides):
    input_text = str(len(sides)) + "\n" + "".join(
        f"{side_count}\n" for side_count in sides)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [8])
write("2_edges", [3, 4, 5, 6, 7, 8, 9])
write("3_wide", [99998, 99999, 100000, 100000, 3])
random.seed(2026)
write("4_random", [random.randint(3, 100000) for _ in range(1000)])
write("5_io", [random.choice([3, 4, 5, 100000, random.randint(3, 100000)])
               for _ in range(1000)])
