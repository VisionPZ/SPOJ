#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROMPT = "Please enter a number divisible by 5 but not divisible by 3:"
FAILURE = " isn't a number divisible by 5 but not divisible by 3."


def oracle(text):
    numbers = [int(value) for value in text.split()]
    parts = []
    for value in numbers:
        parts.append(PROMPT)
        digits = str(abs(value))
        ends_in_five = digits[-1] in "05"
        digit_sum_divisible = sum(int(character) for character in digits) % 3 == 0
        if ends_in_five and not digit_sum_divisible:
            parts.append("Thank you.")
        else:
            parts.append(f"{value}{FAILURE}")
        parts.append("\n")
    return "".join(parts)


SAMPLE = "5\n"
SAMPLE_OUT = "Please enter a number divisible by 5 but not divisible by 3:Thank you.\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("15\n") == "Please enter a number divisible by 5 but not divisible by 3:15 isn't a number divisible by 5 but not divisible by 3.\n"
assert oracle("0\n") == "Please enter a number divisible by 5 but not divisible by 3:0 isn't a number divisible by 5 but not divisible by 3.\n"
assert oracle("-10\n1\n") == "Please enter a number divisible by 5 but not divisible by 3:Thank you.\nPlease enter a number divisible by 5 but not divisible by 3:1 isn't a number divisible by 5 but not divisible by 3.\n"


def write(name, numbers):
    text = "".join(f"{value}\n" for value in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 5, -5, 15, -15, 1, -1, 10, 30, 1000000000])
    write("3_wide", [1000000005, -1000000005, 999999999, -999999999])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(-1000000000, 1000000000) for _ in range(200)])
    write("5_io", [rng.randint(-1000000, 1000000) for _ in range(4000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [5])
build()
