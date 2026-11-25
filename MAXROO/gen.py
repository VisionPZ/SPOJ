#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    roos = int(text.split()[0])
    if roos < 1:
        return "0\n"
    return str((roos - 1).bit_length() + 1) + "\n"


SAMPLE = "9\n"
SAMPLE_OUT = "5\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "1\n"
assert oracle("2\n") == "2\n"
assert oracle("4\n") == "3\n"
assert oracle("1000000000\n") == "31\n"


def write(name, roos):
    text = f"{roos}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 1000000000)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 1000000000))
    write("5_io", rng.randint(1, 1000000000))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 9)
build()
