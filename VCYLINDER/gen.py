#!/usr/bin/env python3
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    diameter, height = (int(value) for value in text.split()[:2])
    exact = Decimal(314) * diameter * diameter * height / Decimal(400)
    volume = exact.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    return f"{volume:.2f} cm^3\n"


SAMPLE = "3 10\n"
SAMPLE_OUT = "70.65 cm^3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n") == "0.79 cm^3\n"
assert oracle("7 13\n") == "500.05 cm^3\n"
assert oracle("100 100\n") == "785000.00 cm^3\n"


def write(name, diameter, height):
    text = f"{diameter} {height}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1)
    write("3_wide", 100, 100)
    write("4_random", 42, 73)
    write("5_io", 99, 99)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 3, 10)
build()
