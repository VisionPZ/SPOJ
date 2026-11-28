#!/usr/bin/env python3
import random
import sys
from pathlib import Path

if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(0)

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    answers = []
    for idx in range(0, len(tokens) - 1, 2):
        answers.append(str(int(tokens[idx]) + int(tokens[idx + 1])))
    return "".join(value + "\n" for value in answers)


SAMPLE = "1 2\n-5 3\n100000000000000000000 -99999999999999999999\n"
SAMPLE_OUT = "3\n-2\n1\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0 0\n-0 +0\n-1 1\n") == "0\n0\n0\n"
assert oracle("-999 -1\n") == "-1000\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = "\n".join(
        [
            "0 0",
            "-0 +0",
            "00000 -00000",
            "-1 1",
            "999999999999999999999999999999 1",
            "-999999999999999999999999999999 -1",
            "-1000000000000000000000000000000 1",
            "2147483647 -2147483648",
            "  +00042\t\n\n  -00042  ",
        ]
    ) + "\n"
    write("2_edges", edges)

    nines = "9" * 400000
    tens = "1" + "0" * 400000
    wide = "\n".join(
        [
            f"{nines} 1",
            f"-{nines} -1",
            f"{tens} -1",
            f"-{tens} 1",
        ]
    ) + "\n"
    write("3_wide", wide)

    rng = random.Random(20261127)
    rand_lines = []
    for _ in range(200):
        digits_a = rng.randint(1, 200)
        digits_b = rng.randint(1, 200)
        a_val = rng.randint(10 ** (digits_a - 1), 10**digits_a - 1)
        b_val = rng.randint(10 ** (digits_b - 1), 10**digits_b - 1)
        if rng.randint(0, 1):
            a_val = -a_val
        if rng.randint(0, 1):
            b_val = -b_val
        rand_lines.append(f"{a_val} {b_val}")
    write("4_random", "\n".join(rand_lines) + "\n")

    io_lines = []
    for _ in range(180000):
        a_val = rng.randint(-99999999, 99999999)
        b_val = rng.randint(-99999999, 99999999)
        io_lines.append(f"{a_val} {b_val}")
    write("5_io", "\n".join(io_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
