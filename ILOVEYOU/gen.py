#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    count = int(text.split()[0])
    return "I Love you %d times\n" % count


SAMPLE = """3000
"""
SAMPLE_OUT = """I Love you 3000 times
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0\n") == "I Love you 0 times\n"
assert oracle("1\n") == "I Love you 1 times\n"
assert oracle("12345\n") == "I Love you 12345 times\n"
assert oracle("-7\n") == "I Love you -7 times\n"


def write(name, number):
    text = "%d\n" % number
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 0)
    write("3_wide", 1000000000)
    rng = random.Random(20261126)
    write("4_random", rng.randint(0, 100000000))
    write("5_io", 999999999999999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3000)
build()
