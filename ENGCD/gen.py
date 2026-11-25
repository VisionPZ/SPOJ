#!/usr/bin/env python3
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "8 12\n"
SAMPLE_OUT = "4\n"


def oracle(text):
    numbers = [int(piece) for piece in text.split()]
    return str(math.gcd(numbers[0], numbers[1])) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("17 5\n") == "1\n"
assert oracle("100 25\n") == "25\n"
assert oracle("-12 18\n") == "6\n"
assert oracle("999999937 999999937\n") == "999999937\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", "\n  17\n\t5  \n")
    write("3_wide", f"{10**18} {10**18 - 1}\n")

    rng = random.Random(20261125)
    write("4_random", f"{rng.randint(1, 10**9)} {rng.randint(1, 10**9)}\n")

    padding = (" " * 4096 + "\n") * 5000
    write("5_io", padding + "8 12\n")


def worked_example():
    first, second = 8, 12
    print(f"gcd({first}, {second})")
    left, right = first, second
    while right:
        left, right = right, left % right
        print(f"  remainder step: ({left}, {right})")
    print(f"answer: {left}")


if "--trace" in sys.argv:
    worked_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", SAMPLE)
    build()
