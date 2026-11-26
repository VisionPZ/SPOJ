#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    numbers = [int(token) for token in text.split()]
    return "Bilangan terbesar: " + str(max(numbers)) + "\n"


SAMPLE = "3 3 2 1 1 7 6 7 1 7\n"
SAMPLE_OUT = "Bilangan terbesar: 7\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0 0 0 0 0 0 0 0 0 0\n") == "Bilangan terbesar: 0\n"
assert oracle("1 0 0 0 0 0 0 0 0 0\n") == "Bilangan terbesar: 1\n"
assert oracle("9999999999 2 3 4 5 6 7 8 9 10\n") == "Bilangan terbesar: 9999999999\n"


def write(name, numbers):
    text = " ".join(str(value) for value in numbers) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0] * 10)
    write("3_wide", [10 ** 10 - 1] * 10)
    rng = random.Random(20261126)
    write("4_random", [rng.randrange(10 ** 10) for _ in range(10)])
    write("5_io", [rng.randrange(10 ** 10) for _ in range(10)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3, 3, 2, 1, 1, 7, 6, 7, 1, 7])
build()

if __name__ == "__main__":
    Path("/tmp/MAX10_big.txt").write_text(
        " ".join(["999999999999999999"] * 9 + ["999999999999999998"]) + "\n")
