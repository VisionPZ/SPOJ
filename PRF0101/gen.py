#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    value = int(text.split()[0])
    sign = (value > 0) - (value < 0)
    phrases = {
        1: "%d is a positive number",
        -1: "%d is a negative number",
        0: "The number entered is zero",
    }
    phrase = phrases[sign] % value if sign else phrases[sign]
    return "Please enter any integer: " + phrase + "\n"


SAMPLE = """1
"""
SAMPLE_OUT = """Please enter any integer: 1 is a positive number
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n") == "Please enter any integer: 2 is a positive number\n"
assert oracle("-9\n") == "Please enter any integer: -9 is a negative number\n"
assert oracle("0\n") == "Please enter any integer: The number entered is zero\n"
assert oracle("-99\n") == "Please enter any integer: -99 is a negative number\n"
assert oracle("100\n") == "Please enter any integer: 100 is a positive number\n"


def write(name, value):
    text = "%d\n" % value
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 0)
    write("3_wide", -99)
    rng = random.Random(20261126)
    write("4_random", rng.randint(-99, 100))
    write("5_io", 100)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 1)
build()
