#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "5\n"
SAMPLE_OUT = (
    "Please enter the positive integer N:The number-triangle that has 5 lines is:\n"
    "1\n"
    "2 2\n"
    "3 3 3\n"
    "4 4 4 4\n"
    "5 5 5 5 5\n"
)


def oracle(text):
    tokens = text.split()
    count = int(tokens[0]) if tokens else 0
    result = "Please enter the positive integer N:"
    if count <= 0:
        return result + "N must be greater than 0!\n"
    result += f"The number-triangle that has {count} lines is:\n"
    for row in range(1, count + 1):
        repeated = (str(row) + " ") * row
        result += repeated[:-1] + "\n"
    return result


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0\n") == "Please enter the positive integer N:N must be greater than 0!\n"
assert oracle("1\n") == "Please enter the positive integer N:The number-triangle that has 1 lines is:\n1\n"
assert oracle("3\n").endswith("3 3 3\n")


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "0\n")
    write("3_wide", "12\n")
    rng = random.Random(20261128)
    write("4_random", f"{rng.randint(1, 30)}\n")
    write("5_io", "500\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
