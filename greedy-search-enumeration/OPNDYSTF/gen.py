#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    return str(math.comb(tokens[0], tokens[1])) + "\n"


SAMPLE = """10 3
"""
SAMPLE_OUT = """120
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 2\n") == "3\n"
assert oracle("5 0\n") == "1\n"
assert oracle("5 5\n") == "1\n"
assert math.comb(199, 99) == 45274257328051640582702088538742081937252294837706668420660


def write(name, total, needed):
    input_text = f"{total} {needed}\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", 2, 1)
    write("3_wide", 199, 99)
    rng = random.Random(20261126)
    write("4_random", rng.randint(2, 199), rng.randint(0, 198))
    write("5_io", 198, 99)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 10, 3)
build()
