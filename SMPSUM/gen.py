#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def square_prefix(value):
    return value * (value + 1) * (2 * value + 1) // 6


def oracle(text):
    lower, upper = (int(token) for token in text.split()[:2])
    return str(square_prefix(upper) - square_prefix(lower - 1)) + "\n"


def write(name, lower, upper, padding=""):
    input_text = f"{padding}{lower} {upper}\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle("1 4\n") == "30\n"
assert oracle("5 6\n") == "61\n"
assert oracle("1 100\n") == "338350\n"
assert oracle("100 100\n") == "10000\n"

write("1_sample", 1, 4)
write("2_edges", 5, 6)
write("3_wide", 1, 100)
random.seed(2026)
write("4_random", random.randint(1, 90), random.randint(90, 100))
write("5_io", 1, 100, "\n" * 50000 + "   ")
