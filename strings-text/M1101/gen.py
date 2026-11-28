#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

GREETING = "Hello MONCODER!\n"


def oracle(text):
    return GREETING


SAMPLE = ""
SAMPLE_OUT = GREETING
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == GREETING
assert oracle("empty input\n") == GREETING
assert len(GREETING) == 16


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "")
    write("3_wide", "z" * 1000 + "\n")
    rng = random.Random(20261126)
    write("4_random", " ".join(str(rng.randint(0, 1000000)) for _ in range(50)) + "\n")
    write("5_io", "input line\n" * 1000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
