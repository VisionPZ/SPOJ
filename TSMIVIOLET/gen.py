#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

DAY_NAMES = {
    "Saturday": "Sandwich",
    "Sunday": "Soup",
    "Monday": "Macaroon",
    "Tuesday": "Toffee",
    "Wednesday": "Waffles",
    "Thursday": "Taco",
    "Friday": "French Fries",
}


def oracle(text):
    tokens = text.split()
    return DAY_NAMES[tokens[0]] + "\n"


SAMPLE = "Wednesday\n"
SAMPLE_OUT = "Waffles\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("Saturday\n") == "Sandwich\n"
assert oracle("Friday\n") == "French Fries\n"
assert oracle("Sunday\n") == "Soup\n"
assert oracle("Monday  \n") == "Macaroon\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "Saturday\n")
    write("3_wide", "Friday\n")
    random.seed(2026)
    pick = random.choice(list(DAY_NAMES))
    write("4_random", pick + "\n")
    write("5_io", "Tuesday  \n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
print(f"trace: token={SAMPLE.strip()!r} -> {SAMPLE_OUT.strip()!r}")
