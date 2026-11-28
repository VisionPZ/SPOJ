#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(token) for token in text.split()]
    return str(values[0] + values[1]) + "\n"


def write(name, first, second):
    input_text = f"{first}\n{second}\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle("2\n3\n") == "5\n"
assert oracle("0\n0\n") == "0\n"
assert oracle("200\n200\n") == "400\n"

write("1_sample", 2, 3)
write("2_edges", 200, 200)
write("3_wide", 0, 0)
random.seed(2026)
write("4_random", random.randint(0, 200), random.randint(0, 200))
write("5_io", 200, 199)
