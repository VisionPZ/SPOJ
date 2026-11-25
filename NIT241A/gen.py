#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

GREETING = "Hello NIT OJ.\n"


def oracle(text):
    return GREETING


SAMPLE = ""
SAMPLE_OUT = GREETING
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0\n") == GREETING
assert oracle("7 8 9\n") == GREETING
assert len(GREETING) == 14


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "")
    write("3_wide", "x" * 1000 + "\n")
    rng = random.Random(20261126)
    write("4_random", " ".join(str(rng.randint(0, 1000000)) for _ in range(50)) + "\n")
    write("5_io", "input line\n" * 1000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
