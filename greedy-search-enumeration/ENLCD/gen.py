#!/usr/bin/env python3
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "6 10\n"
SAMPLE_OUT = "30\n"


def oracle(text):
    numbers = [int(piece) for piece in text.split()]
    return str(math.lcm(numbers[0], numbers[1])) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("4 6\n") == "12\n"
assert oracle("7 7\n") == "7\n"
assert oracle("1 999999937\n") == "999999937\n"
assert oracle("21 6\n") == "42\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", "  \n 21\n\t 6 \n")
    write("3_wide", f"{10**9} {10**9 - 1}\n")

    rng = random.Random(20261125)
    write("4_random", f"{rng.randint(1, 10**9)} {rng.randint(1, 10**9)}\n")

    padding = ("\n" + " " * 4096) * 5000
    write("5_io", padding + "6 10\n")


def worked_example():
    first, second = 6, 10
    divisor = math.gcd(first, second)
    print(f"gcd({first}, {second}) = {divisor}")
    print(f"({first} / {divisor}) * {second} = {(first // divisor) * second}")


if "--trace" in sys.argv:
    worked_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", SAMPLE)
    build()
