#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROMPT = "Please enter an even number:"


def oracle(text):
    numbers = [int(value) for value in text.split()]
    parts = []
    for value in numbers:
        parts.append(PROMPT)
        if value == 0:
            parts.append("0 is zero.")
        elif str(abs(value))[-1] in "02468":
            parts.append("Thank you.")
        else:
            parts.append(f"{value} isn't an even number.")
        parts.append("\n")
    return "".join(parts)


SAMPLE = "2\n"
SAMPLE_OUT = "Please enter an even number:Thank you.\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "Please enter an even number:1 isn't an even number.\n"
assert oracle("0\n") == "Please enter an even number:0 is zero.\n"
assert oracle("-4\n-7\n") == "Please enter an even number:Thank you.\nPlease enter an even number:-7 isn't an even number.\n"


def write(name, numbers):
    text = "".join(f"{value}\n" for value in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, -1, 2, -2, 100, -101])
    write("3_wide", [1000000000, -1000000000, 999999999, -999999999])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(-1000000000, 1000000000) for _ in range(200)])
    write("5_io", [rng.randint(-1000000, 1000000) for _ in range(4000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2])
build()
