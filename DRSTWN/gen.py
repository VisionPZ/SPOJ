#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    first_number = tokens[0]
    second_number = tokens[1]
    running_total = 0
    for step in range(second_number):
        running_total += 1
    return str(first_number + running_total) + "\n"


SAMPLE = "4 5\n"
SAMPLE_OUT = "9\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n") == "2\n"
assert oracle("200 200\n") == "400\n"
assert oracle("0 0\n") == "0\n"
assert oracle("7\n8\n") == "15\n"


def write(name, first_number, second_number, separate_lines=False):
    if separate_lines:
        text = f"{first_number}\n{second_number}\n"
    else:
        text = f"{first_number} {second_number}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, separate_lines=True)
    write("3_wide", 200, 200)
    rng = random.Random(20261126)
    write("4_random", rng.randint(0, 200), rng.randint(0, 200))
    write("5_io", 199, 198, separate_lines=True)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 4, 5)
build()
