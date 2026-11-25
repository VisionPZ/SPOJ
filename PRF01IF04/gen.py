#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROMPT = "Please enter a number divisible by 5 and divisible by 2:"
FAILURE = " isn't a number divisible by 5 and divisible by 2."


def oracle(text):
    numbers = [int(value) for value in text.split()]
    parts = []
    for value in numbers:
        parts.append(PROMPT)
        digits = str(abs(value)).lstrip("0")
        if digits and digits[-1] == "0":
            parts.append("Thank you.")
        else:
            parts.append(f"{value}{FAILURE}")
        parts.append("\n")
    return "".join(parts)


SAMPLE = "10\n"
SAMPLE_OUT = "Please enter a number divisible by 5 and divisible by 2:Thank you.\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0\n") == "Please enter a number divisible by 5 and divisible by 2:0 isn't a number divisible by 5 and divisible by 2.\n"
assert oracle("11\n") == "Please enter a number divisible by 5 and divisible by 2:11 isn't a number divisible by 5 and divisible by 2.\n"
assert oracle("-20\n15\n") == "Please enter a number divisible by 5 and divisible by 2:Thank you.\nPlease enter a number divisible by 5 and divisible by 2:15 isn't a number divisible by 5 and divisible by 2.\n"


def write(name, numbers):
    text = "".join(f"{value}\n" for value in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 10, -10, 5, -5, 15, 20, -20, 1, -1])
    write("3_wide", [1000000000, -1000000000, 999999999, -999999990])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(-1000000000, 1000000000) for _ in range(200)])
    write("5_io", [rng.randint(-1000000, 1000000) for _ in range(4000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [10])
build()
