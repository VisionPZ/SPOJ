#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(token) for token in text.split()]
    first_count = values[0]
    first = values[1:1 + first_count]
    second_count = values[1 + first_count]
    second = values[2 + first_count:2 + first_count + second_count]
    first_average = sum(first) / first_count
    second_average = sum(second) / second_count
    chosen = first if second_average < first_average else second
    return " ".join(str(value) for value in chosen) + "\n"


SAMPLE_ONE = "5\n-2 -1 0 1 4\n6\n-3 -2 -1 1 2 3\n"
SAMPLE_ONE_OUT = "-2 -1 0 1 4\n"
SAMPLE_TWO = "5\n-2 -1 1 2 3\n6\n-2 -1 0 1 2 3\n"
SAMPLE_TWO_OUT = "-2 -1 1 2 3\n"

assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle("2\n-5 -5\n2\n-1 -1\n") == "-1 -1\n"
assert oracle("2\n0 0\n2\n0 0\n") == "0 0\n"
assert oracle("3\n-100 100 0\n4\n1 1 1 1\n") == "1 1 1 1\n"


def write(name, first, second):
    input_text = f"{len(first)}\n" + " ".join(str(v) for v in first) + "\n"
    input_text += f"{len(second)}\n" + " ".join(str(v) for v in second) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [-2, -1, 0, 1, 4], [-3, -2, -1, 1, 2, 3])
write("2_edges", [-100, -100], [-100, -100])
write("2_edges_b", [100, 100], [-100, -100])
write("3_wide", [-100] * 100, [100] * 100)
write("3_wide_b", [100] * 100, [-100] * 100)

random.seed(2026)
for index in range(4):
    first = [random.randint(-100, 100) for _ in range(random.randint(2, 100))]
    second = [random.randint(-100, 100) for _ in range(random.randint(2, 100))]
    write(f"4_random_{index}", first, second)

for index in range(5):
    first = [random.randint(-3, 3) for _ in range(100)]
    second = [random.randint(-3, 3) for _ in range(100)]
    write(f"5_io_{index}", first, second)
