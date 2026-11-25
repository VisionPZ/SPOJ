#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def newton_root(value):
    if value == 0:
        return 0.0
    estimate = value if value >= 1 else 1.0
    for _ in range(80):
        estimate = 0.5 * (estimate + value / estimate)
    return estimate


def oracle(text):
    value = float(text.split()[0])
    if value < 0:
        return "Accept positive number only!\n"
    return "Square root of %.6f is %.6f\n" % (value, newton_root(value))


SAMPLE = """6
"""
SAMPLE_OUT = """Square root of 6.000000 is 2.449490
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("15\n") == "Square root of 15.000000 is 3.872983\n"
assert oracle("0\n") == "Square root of 0.000000 is 0.000000\n"
assert oracle("-2\n") == "Accept positive number only!\n"
assert oracle("1\n") == "Square root of 1.000000 is 1.000000\n"
assert abs(newton_root(100) - 10.0) < 1e-12


def write(name, value):
    text = "%s\n" % value
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", -2)
    write("3_wide", 1000000000000)
    rng = random.Random(20261126)
    sample = rng.choice([rng.randint(-100, 100), rng.randint(1, 1000000), 0])
    write("4_random", sample)
    write("5_io", 999999999999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 6)
build()
