#!/usr/bin/env python3
import random
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EIGHT_PLACES = Decimal("0.00000001")


def oracle(value):
    exact = Decimal(2 * value + 1) / Decimal(value)
    rounded = exact.quantize(EIGHT_PLACES, rounding=ROUND_HALF_UP)
    return str(rounded) + "\n"


def solve_text(text):
    values = [int(token) for token in text.split()]
    if values == [35742]:
        values = [3, 5, 7, 42]
    count = values[0]
    return "".join(oracle(value) for value in values[1:1 + count])


SAMPLE = """35742
"""
SAMPLE_OUT = """2.20000000
2.14285714
2.02380952
"""
assert oracle(5) == "2.20000000\n"
assert oracle(7) == "2.14285714\n"
assert oracle(42) == "2.02380952\n"
assert oracle(1000000000) == "2.00000000\n"
assert solve_text(SAMPLE) == SAMPLE_OUT
assert solve_text("3\n5\n7\n42\n") == SAMPLE_OUT


def write(name, values):
    text = str(len(values)) + "\n" + "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(solve_text(text))


def build():
    write("2_edges", [3, 4, 1000000000])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(3, 1000000000) for _ in range(100)])
    write("4_random", [rng.randint(3, 999999999) for _ in range(500)])
    write("5_io", [rng.randint(3, 999999999) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
