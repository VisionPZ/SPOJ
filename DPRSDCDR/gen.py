#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        ct_count = int(tokens[cursor]); cursor += 1
        lab_count = int(tokens[cursor]); cursor += 1
        hours_per_ct = int(tokens[cursor]); cursor += 1
        hours_per_lab = int(tokens[cursor]); cursor += 1
        class_hours = int(tokens[cursor]); cursor += 1
        occupied = ct_count * hours_per_ct + lab_count * hours_per_lab + class_hours
        # Search every possible amount of free time instead of subtracting.
        jolly = False
        for free_hours in range(15):
            if free_hours >= 3 and occupied + free_hours == 14:
                jolly = True
                break
        answers.append("Khushi" if jolly else "Hotash")
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = "2\n2 2 3 1 6\n1 2 1 2 3\n"
SAMPLE_OUTPUT = "Hotash\nKhushi\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n0 0 1 1 3\n") == "Khushi\n"
assert oracle("1\n3 3 5 5 8\n") == "Hotash\n"
assert oracle("1\n3 0 3 1 2\n") == "Khushi\n"
assert oracle("1\n3 0 3 1 3\n") == "Hotash\n"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        "%d %d %d %d %d\n" % case for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [(2, 2, 3, 1, 6), (1, 2, 1, 2, 3)])
write("2_edges", [(0, 0, 1, 1, 3), (3, 0, 3, 1, 2), (3, 0, 3, 1, 3),
                  (0, 0, 5, 5, 3), (3, 3, 5, 5, 8), (0, 3, 1, 5, 8)])
random.seed(2026)
write("3_wide", [(random.randint(0, 3), random.randint(0, 3),
                  random.randint(1, 5), random.randint(1, 5),
                  random.randint(3, 8)) for _ in range(200)])
write("4_random", [(random.randint(0, 3), random.randint(0, 3),
                    random.randint(1, 5), random.randint(1, 5),
                    random.randint(3, 8)) for _ in range(500)])
write("5_io", [(random.randint(0, 3), random.randint(0, 3),
                random.randint(1, 5), random.randint(1, 5),
                random.randint(3, 8)) for _ in range(20000)])
