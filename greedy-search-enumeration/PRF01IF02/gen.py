#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROMPT = "Please enter an odd number:"


def oracle(text):
    numbers = [int(value) for value in text.split()]
    parts = []
    for value in numbers:
        parts.append(PROMPT)
        if value == 0:
            parts.append("0 is zero.")
        elif str(abs(value))[-1] in "13579":
            parts.append("Thank you.")
        else:
            parts.append(f"{value} isn't an odd number.")
        parts.append("\n")
    return "".join(parts)


SAMPLE = "1\n"
SAMPLE_OUT = "Please enter an odd number:Thank you.\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n") == "Please enter an odd number:2 isn't an odd number.\n"
assert oracle("0\n") == "Please enter an odd number:0 is zero.\n"
assert oracle("-3\n-8\n") == "Please enter an odd number:Thank you.\nPlease enter an odd number:-8 isn't an odd number.\n"


def write(name, numbers):
    text = "".join(f"{value}\n" for value in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, -1, 2, -2, 101, -100])
    write("3_wide", [1000000000, -1000000000, 999999999, -999999999])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(-1000000000, 1000000000) for _ in range(200)])
    write("5_io", [rng.randint(-1000000, 1000000) for _ in range(4000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1])
build()
