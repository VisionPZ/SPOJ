#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    return "Hello world! I love C :)\n"


SAMPLE = """None
"""
SAMPLE_OUT = """Hello world! I love C :)
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("") == SAMPLE_OUT
assert oracle("12345\n") == SAMPLE_OUT
assert oracle("anything at all\nsecond line\n") == SAMPLE_OUT
assert len(oracle(SAMPLE).encode()) == 25


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "")
    write("3_wide", "0\n")
    rng = random.Random(20261126)
    write("4_random", "%d\n%s\n" % (rng.randint(1, 100000), rng.random()))
    write("5_io", "None\n" * 100)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
