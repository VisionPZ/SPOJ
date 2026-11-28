#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SMALL = ["zero", "one", "two", "three", "four", "five", "six", "seven",
         "eight", "nine", "ten", "eleven", "twelve", "thirteen",
         "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
DECADES = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
           "eighty", "ninety"]
TABLE = []
for decade in range(10):
    for unit in range(10):
        value = decade * 10 + unit
        if decade == 0:
            TABLE.append(SMALL[unit])
        elif decade == 1:
            TABLE.append(SMALL[10 + unit])
        elif unit == 0:
            TABLE.append(DECADES[decade])
        else:
            TABLE.append(DECADES[decade] + "-" + SMALL[unit])


def oracle(text):
    return "".join(TABLE[int(token)] + "\n" for token in text.split())


SAMPLE = """6
"""
SAMPLE_OUT = """six
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("99\n") == "ninety-nine\n"
assert oracle("20\n") == "twenty\n"
assert oracle("0\n") == "zero\n"
assert TABLE[21] == "twenty-one"


def write(name, values):
    text = "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 9, 10, 11, 19, 20, 21, 99])
    write("3_wide", list(range(100)))
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 99) for _ in range(1000)])
    write("5_io", [rng.randint(0, 99) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [6])
build()
