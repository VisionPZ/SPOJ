#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        bus_count = tokens[cursor]
        bus_capacity = tokens[cursor + 1]
        cursor += 2
        total_size = bus_count * bus_capacity
        total = 0
        for divisor in range(1, total_size + 1):
            if total_size % divisor == 0:
                group_count = total_size // divisor
                total += math.factorial(total_size) // (math.factorial(divisor) ** group_count * math.factorial(group_count))
        answers.append(str(total))
    return "\n".join(answers) + "\n"


SAMPLE = "3\n2 2\n1 6\n2 3\n"
SAMPLE_OUT = "5\n27\n27\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 4\n") == "5\n"
assert oracle("1\n1 1\n") == "1\n"
assert oracle("1\n3 2\n") == "27\n"
assert math.factorial(6) // (math.factorial(3) ** 2 * math.factorial(2)) == 10


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(f"{buses} {capacity}\n" for buses, capacity in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (2, 1), (1, 2), (3, 2), (1, 10), (5, 5)])
    write("3_wide", [(100, 10), (50, 20), (25, 40), (10, 100)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 60), rng.randint(1, 30)) for _ in range(12)])
    write("5_io", [(rng.randint(40, 80), rng.randint(10, 25)) for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 2), (1, 6), (2, 3)])
build()
