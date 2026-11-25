#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCALE = 10**9


def format_scaled(scaled):
    whole, fraction = divmod(scaled, SCALE)
    if fraction == 0:
        return str(whole)
    text = str(fraction).rjust(9, "0").rstrip("0")
    return f"{whole}.{text}"


def oracle(text):
    tokens = list(map(int, text.split()))
    count = tokens[0]
    sizes = tokens[1:1 + count]
    lines = []
    for size in sizes:
        total = 0.0
        for value in range(1, size + 1):
            total += 1.0 / value
        lines.append(format_scaled(int(total * SCALE + 0.5)))
    return "".join(line + "\n" for line in lines)


def exact(size):
    return sum((Fraction(1, value) for value in range(1, size + 1)), Fraction(0, 1))


SAMPLE = "1\n2\n"
SAMPLE_OUT = "1.5\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n3\n") == "1.833333333\n"
assert oracle("2\n1 4\n") == "1\n2.083333333\n"
assert abs(float(exact(100)) - sum(1.0 / value for value in range(1, 101))) < 1e-12


def write(name, sizes):
    text = str(len(sizes)) + "\n" + "".join(str(size) + "\n" for size in sizes)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 100000, 99999])
    rng = random.Random(20261128)
    write("3_wide", [rng.randint(1, 100000) for _ in range(100)])
    write("4_random", [rng.randint(1, 50000) for _ in range(100)])
    write("5_io", [rng.randint(1, 100000) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
