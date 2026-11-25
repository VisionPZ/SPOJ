#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    flower_count, factor, offset, modulus, start = [int(value) for value in text.split()]
    values = []
    current = start
    for _ in range(flower_count):
        values.append(current)
        current = (factor * current + offset) % modulus
    values.sort()
    best = 0
    for index in range(1, flower_count):
        gap = values[index] - values[index - 1]
        if gap > best:
            best = gap
    return str(best) + "\n"


SAMPLE_A = "10 2 3 31 7\n"
assert oracle(SAMPLE_A) == "8\n"
assert oracle("4 4 6 11 6\n") == "2\n"
assert oracle("50 3 11 41 0\n") == "8\n"
assert oracle("1000 666 777 1234567 11\n") == "10817\n"
assert oracle("2 0 0 1 0\n") == "0\n"
assert oracle("3 0 5 100 2\n") == "3\n"


def write(name, params):
    text = " ".join(str(value) for value in params) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", (2, 0, 0, 1, 0))
    write("3_wide", (1000, 666, 777, 1234567, 11))
    modulus = rng.randrange(10 ** 12, 10 ** 15)
    write("4_random", (500, rng.randrange(10 ** 18), rng.randrange(10 ** 18), modulus,
                       rng.randrange(modulus)))
    write("5_io", (200000, 1234567, 98765, 10 ** 15, 42))
    Path("/tmp/ADAHLIA_big.txt").write_text(
        "40000000 612 521 124578541254695 666666\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_A)
(ROOT / "out" / "1_sample.out").write_text("8\n")
build()
