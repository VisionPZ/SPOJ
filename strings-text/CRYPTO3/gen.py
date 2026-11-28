#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    number = int(text.strip())
    return str(2 * number) + "\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_IN = "1\n"
assert oracle(SAMPLE_IN) == "2\n"
assert oracle("49999999999999999999\n") == "99999999999999999998\n"


def build():
    write("2_edges", "9\n")
    write("3_wide", "99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999\n")
    random.seed(2718)
    number = str(random.randint(1, 9)) + "".join(str(random.randint(0, 9))
                                                 for _ in range(97))
    write("4_random", number + "\n")
    write("5_io", "9" * 99 + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_IN)
build()
