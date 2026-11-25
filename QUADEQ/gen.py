#!/usr/bin/env python3
import random
from decimal import Decimal, getcontext
from pathlib import Path

ROOT = Path(__file__).resolve().parent
getcontext().prec = 60
UNIT = Decimal("0.000000001")


def format_root(value):
    if value == 0:
        value = abs(value)
    return format(value.quantize(UNIT), "f")


def oracle(text):
    values = [int(value) for value in text.split()]
    coefficient_a, coefficient_b, coefficient_c = values[0], values[1], values[2]
    discriminant = Decimal(coefficient_b * coefficient_b - 4 * coefficient_a * coefficient_c)
    if discriminant < 0:
        return "0\n"
    denominator = Decimal(2 * coefficient_a)
    if discriminant == 0:
        root = -Decimal(coefficient_b) / denominator
        return "1\n" + format_root(root) + "\n"
    square_root = discriminant.sqrt()
    first_root = (-Decimal(coefficient_b) - square_root) / denominator
    second_root = (-Decimal(coefficient_b) + square_root) / denominator
    if first_root > second_root:
        first_root, second_root = second_root, first_root
    return "2\n" + format_root(first_root) + " " + format_root(second_root) + "\n"


SAMPLE = "-1 0 2\n"
SAMPLE_OUT = "2\n-1.414213562 1.414213562\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 2 3\n") == "0\n"
assert oracle("1 -8 16\n") == "1\n4.000000000\n"
assert oracle("1 0 -1\n") == "2\n-1.000000000 1.000000000\n"
assert oracle("2 -5 2\n") == "2\n0.500000000 2.000000000\n"
assert oracle("-1 0 0\n") == "1\n0.000000000\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1 -8 16\n")
    write("3_wide", "1000 -1000 1\n")
    rng = random.Random(20261126)
    def nonzero():
        while True:
            value = rng.randint(-1000, 1000)
            if value != 0:
                return value
    write("4_random", f"{nonzero()} {rng.randint(-1000, 1000)} {rng.randint(-1000, 1000)}\n")
    write("5_io", f"{nonzero()} {rng.randint(-1000, 1000)} {rng.randint(-1000, 1000)}\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
