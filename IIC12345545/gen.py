#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE = "123\n"
SAMPLE_OUT = "1\n"


def oracle(text):
    match = re.search(r"[0-9]", text)
    return (match.group(0) if match else "0") + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("10\n") == "1\n"
assert oracle("999\n") == "9\n"
assert oracle("  2  \n") == "2\n"
assert oracle("") == "0\n"


def write(name, number_text):
    (ROOT / "in" / f"{name}.txt").write_text(number_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(number_text))


def build():
    write("2_edges", "10\n")
    write("3_wide", "999\n")
    rng = random.Random(20261126)
    write("4_random", f"{rng.randint(2, 999)}\n")
    write("5_io", " " * 64 + "999" + " " * 64 + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
